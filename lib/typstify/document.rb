# frozen_string_literal: true

module Typstify
  # The pipeline: resolve a template, build an isolated workspace, check fonts,
  # compile, hand back bytes. Everything public in this gem funnels through here.
  class Document
    def initialize(template:, data: nil, assigns: {}, config: Typstify.config)
      @template = template
      @data = data
      @assigns = assigns
      @config = config
    end

    # @return [String] PDF bytes, ASCII-8BIT
    def to_pdf
      # Validate first: a bad value should fail before we create a workspace,
      # let alone start the compiler.
      payload = @data.nil? ? nil : Data.dump(@data)
      resolution = Resolver.new(@config).call(@template)
      source = read_source(resolution)

      Workspace.build(source: source, data: payload, config: @config) do |workspace|
        check_fonts(workspace)
        Adapter.compile_pdf(
          main_path: workspace.main_path,
          root: workspace.dir,
          template: resolution.name,
          config: @config
        )
      end
    end

    private

    def read_source(resolution)
      # Explicit UTF-8: templates contain typographic characters, and a
      # container with no LANG set defaults to US-ASCII, which would turn an
      # em dash into an encoding error at render time.
      raw = File.read(resolution.path, encoding: Encoding::UTF_8)
      return raw unless resolution.erb?

      ErbPipeline.render(raw, data: @data, assigns: @assigns)
    end

    # Resolve the fonts a template names before handing it to the compiler.
    #
    # Two reasons this stays even now that the binding reports warnings itself
    # (typst >= 0.15.1.6): it can raise *before* a compile rather than after
    # one, and it is the only signal at all on older bindings. Checks the main
    # template and everything copied alongside it, because a missing family is
    # just as likely to be declared in shared/branding.typ.
    def check_fonts(workspace)
      sources = [workspace.main_path, *Dir.glob(workspace.dir.join("**", "*.typ"))]
      combined = sources.uniq.map { |path| File.read(path, encoding: Encoding::UTF_8) }.join("\n")
      include_system = !@config.ignore_system_fonts
      missing = Fonts.missing(combined, @config.font_paths, include_system: include_system)
      return if missing.empty?

      if @config.strict_fonts
        raise FontMissingError.new(
          missing,
          Fonts.search_paths(@config.font_paths, include_system: include_system)
        )
      end

      # Not strict, so this is a warning. Leave it to the compiler when the
      # compiler can speak for itself — its diagnostic carries the line and
      # column, and reporting both would say the same thing twice.
      return if Adapter.warnings_supported?

      @config.on_warning&.call(
        missing.map { |family| "unknown font family: #{family.inspect} (substituted)" },
        @template
      )
    end
  end
end
