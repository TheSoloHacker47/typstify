# frozen_string_literal: true

module Typstify
  # Everything tunable, set once in `config/initializers/typstify.rb`.
  #
  #   Typstify.configure do |c|
  #     c.font_paths   = [Rails.root.join("app/assets/fonts")]
  #     c.pdf_standard = :ua_1
  #   end
  class Config
    # Symbol names for the PDF standards Typst can emit, mapped to the strings
    # the compiler wants. Verified against typst_pdf::PdfStandard.
    PDF_STANDARDS = {
      pdf_1_7: "1.7",
      pdf_2_0: "2.0",
      a_1b: "a-1b",
      a_2b: "a-2b",
      a_3b: "a-3b",
      a_4: "a-4",
      ua_1: "ua-1"
    }.freeze

    attr_writer :template_root, :shared_dir, :font_paths, :package_cache, :on_warning, :strict_fonts

    # Where `.typ` templates live. Also the boundary a template path may not
    # escape (see Resolver).
    def template_root
      @template_root ||= defined?(::Rails) && ::Rails.root ? ::Rails.root.join("app/views") : Pathname.pwd
      Pathname.new(@template_root)
    end

    # Subdirectory of `template_root` copied into every workspace, so
    # `#import "shared/branding.typ"` resolves from any template.
    def shared_dir
      @shared_dir ||= "shared"
    end

    # Directories searched for fonts, in addition to system fonts. The gem's
    # own bundled faces are always appended, so starter templates work with no
    # configuration at all.
    def font_paths
      Array(@font_paths).map { |p| Pathname.new(p) } + [Typstify.bundled_font_path]
    end

    # Directory holding vendored Typst Universe packages, for network-free
    # builds. See docs/fonts-and-docker.md for the platform caveat.
    def package_cache
      @package_cache && Pathname.new(@package_cache)
    end

    # nil (plain PDF), or one of PDF_STANDARDS' keys.
    attr_accessor :pdf_standard

    # The compiler flag string, or nil.
    def pdf_standards
      return [] if pdf_standard.nil?

      key = pdf_standard.to_sym
      value = PDF_STANDARDS[key]
      unless value
        raise ArgumentError,
              "Unknown pdf_standard #{pdf_standard.inspect}. " \
              "Expected one of: #{PDF_STANDARDS.keys.map(&:inspect).join(", ")}"
      end
      [value]
    end

    # Raise FontMissingError instead of warning when a template asks for a font
    # nothing can supply. On in development and test, off in production, where
    # a substituted glyph beats a 500.
    def strict_fonts
      return @strict_fonts unless @strict_fonts.nil?

      @strict_fonts = !defined?(::Rails) || ::Rails.env.nil? || ::Rails.env.development? || ::Rails.env.test?
    end

    # Called as `on_warning.call(warnings, template)` — warnings is an Array of
    # strings. Defaults to Rails.logger.warn.
    def on_warning
      @on_warning ||= lambda do |warnings, template|
        message = "[typstify] #{template}: #{warnings.join("; ")}"
        if defined?(::Rails) && ::Rails.logger
          ::Rails.logger.warn(message)
        else
          warn(message)
        end
      end
    end
  end
end
