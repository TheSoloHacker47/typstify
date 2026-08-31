# frozen_string_literal: true

require "pathname"
require "stringio"

require_relative "typstify/version"
require_relative "typstify/errors"
require_relative "typstify/config"
require_relative "typstify/escaping"
require_relative "typstify/data"
require_relative "typstify/warnings"
require_relative "typstify/fonts"
require_relative "typstify/resolver"
require_relative "typstify/workspace"
require_relative "typstify/erb_pipeline"
require_relative "typstify/adapter"
require_relative "typstify/document"

require_relative "typstify/engine" if defined?(Rails::Engine)

# PDF generation for Rails on the Typst engine.
#
#   Typstify.render(template: "invoices/show", data: { number: "A-1" })
#
# In a controller, prefer the renderer:
#
#   render pdf: "invoices/show", data: { ... }, filename: "invoice.pdf"
module Typstify
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config
      apply_package_cache!
      config
    end

    # Mostly for specs: drop all configuration and cached font scans.
    def reset!
      @config = Config.new
      Fonts.reset!
      config
    end

    # Compile a template to PDF.
    #
    # @param template [String] e.g. "invoices/show"
    # @param data [Object] anything JSON-serializable; read in the template
    #   with `#let data = json("data.json")`
    # @param assigns [Hash] instance variables for ERB mode only
    # @return [String] PDF bytes, ASCII-8BIT
    def render(template:, data: nil, assigns: {})
      Document.new(template: template, data: data, assigns: assigns, config: config).to_pdf
    end

    # Render and attach in one step.
    #
    #   Typstify.render_and_attach(user.documents,
    #                              template: "certificates/completion",
    #                              data: cert_data, filename: "certificate.pdf")
    #
    # @param attachable [#attach] an ActiveStorage has_one/has_many attachment proxy
    def render_and_attach(attachable, template:, filename:, data: nil, assigns: {},
                          content_type: "application/pdf")
      pdf = render(template: template, data: data, assigns: assigns)
      attachable.attach(
        io: StringIO.new(pdf),
        filename: filename,
        content_type: content_type
      )
    end

    def root
      @root ||= Pathname.new(__dir__).join("..").expand_path
    end

    # Faces shipped with the gem, always on the font search path so the starter
    # templates render with no configuration.
    def bundled_font_path
      root.join("fonts")
    end

    # The starter template pack, copied by `rails g typstify:template`.
    def template_pack_path
      root.join("templates")
    end

    # Point Typst's package resolution at the configured cache.
    #
    # Typst looks in the platform data directory, which on Linux — and so in
    # every Docker image — is XDG_DATA_HOME. Set once at boot rather than around
    # each compile, because mutating ENV per render is not thread-safe and
    # concurrent rendering is a supported use. On macOS the platform directory
    # is fixed and this has no effect; see docs/fonts-and-docker.md.
    def apply_package_cache!
      cache = config.package_cache
      return if cache.nil?

      ENV["XDG_DATA_HOME"] = cache.expand_path.to_s
    end
  end
end
