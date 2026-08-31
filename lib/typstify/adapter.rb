# frozen_string_literal: true

require "typst"

module Typstify
  # The only file in this gem that knows the `typst` binding exists.
  #
  # Everything upstream might rename — the constructor shape, the option names,
  # how compiled bytes come back — is contained here, so a binding release
  # breaks one file instead of five. Verified against typst 0.15.1.5 and .6.
  module Adapter
    # The binding surfaces compile failures as ArgumentError, carrying the same
    # codespan-formatted diagnostic the CLI prints.
    BINDING_ERROR = ArgumentError

    module_function

    # Whether the installed binding hands back the warnings from a *successful*
    # compile. Added in typst 0.15.1.6 (actsasflinn/typst-rb#10); before that
    # they were discarded and there was nothing to forward.
    #
    # Detected by capability rather than by version string: a version
    # comparison would be one more thing to keep in step with upstream, and
    # this is the actual question being asked.
    def warnings_supported?
      return @warnings_supported unless @warnings_supported.nil?

      @warnings_supported = ::Typst::Document.method_defined?(:warnings)
    end

    # Specs install and uninstall fake documents; nothing else should need this.
    def reset_capability_cache!
      @warnings_supported = nil
    end

    # @param main_path [Pathname] the workspace's main.typ
    # @param root [Pathname] the workspace; Typst's sandbox boundary
    # @param template [String] the name to show in errors
    # @param config [Typstify::Config] supplies the fonts and the PDF standard
    # @return [String] PDF bytes, ASCII-8BIT
    def compile_pdf(main_path:, root:, template:, config: Typstify.config)
      document = Typst(
        main_path.to_s,
        root: root.to_s,
        font_paths: config.font_paths.map(&:to_s),
        ignore_system_fonts: config.ignore_system_fonts,
        pdf_standards: config.pdf_standards
      ).compile(:pdf)

      dispatch_warnings(document, root: root, template: template, config: config)

      # PdfDocument#bytes is a per-page array of integer arrays; #pages packs
      # each one. A PDF is always a single "page" here — the whole document.
      document.pages.first.to_s.b
    rescue BINDING_ERROR => e
      raise translate(e, root: root, template: template, config: config)
    end

    # Forward the warnings from a compile that succeeded. Each one arrives as a
    # formatted codespan block naming the workspace tmpdir, so it gets the same
    # path rewriting an error does — a developer wrote app/views/invoices/show.typ
    # and should read about that file.
    def dispatch_warnings(document, root:, template:, config:)
      return unless document.respond_to?(:warnings)

      diagnostics = Array(document.warnings).flat_map do |warning|
        Warnings.parse(Warnings.rewrite_paths(warning, root, template))
      end
      return if diagnostics.empty?

      Warnings.dispatch(diagnostics, template, config)
    end

    # Turn the binding's flat diagnostic blob into a CompileError that names the
    # developer's template rather than a tmpdir, and surface any warnings that
    # came along with it through the on_warning hook.
    def translate(error, root:, template:, config:)
      readable = Warnings.rewrite_paths(error.message, root, template)
      diagnostics = Warnings.parse(readable)
      Warnings.dispatch(diagnostics, template, config)

      first = diagnostics.find { |d| d.severity == :error }
      CompileError.new(
        template: template,
        typst_message: readable.strip,
        line: first&.line,
        column: first&.column
      )
    end
  end
end
