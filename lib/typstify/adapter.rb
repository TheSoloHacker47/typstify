# frozen_string_literal: true

require "typst"

module Typstify
  # The only file in this gem that knows the `typst` binding exists.
  #
  # Everything upstream might rename — the constructor shape, the option names,
  # how compiled bytes come back — is contained here, so a binding release
  # breaks one file instead of five. Verified against typst 0.15.1.5.
  module Adapter
    # The binding surfaces compile failures as ArgumentError, carrying the same
    # codespan-formatted diagnostic the CLI prints.
    BINDING_ERROR = ArgumentError

    module_function

    # @param main_path [Pathname] the workspace's main.typ
    # @param root [Pathname] the workspace; Typst's sandbox boundary
    # @param font_paths [Array<Pathname>]
    # @param pdf_standards [Array<String>] e.g. ["ua-1"]
    # @param template [String] the name to show in errors
    # @param config [Typstify::Config]
    # @return [String] PDF bytes, ASCII-8BIT
    def compile_pdf(main_path:, root:, font_paths:, pdf_standards:, template:, config: Typstify.config)
      document = Typst(
        main_path.to_s,
        root: root.to_s,
        font_paths: font_paths.map(&:to_s),
        pdf_standards: pdf_standards
      ).compile(:pdf)

      # PdfDocument#bytes is a per-page array of integer arrays; #pages packs
      # each one. A PDF is always a single "page" here — the whole document.
      document.pages.first.to_s.b
    rescue BINDING_ERROR => e
      raise translate(e, root: root, template: template, config: config)
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
