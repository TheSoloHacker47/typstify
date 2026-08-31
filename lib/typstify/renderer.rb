# frozen_string_literal: true

require "action_controller"

module Typstify
  # Registers `render pdf:` on every controller.
  #
  #   render pdf: "invoices/show",
  #          data: { number: "A-1" },
  #          filename: "invoice-A-1.pdf",
  #          disposition: :inline
  #
  # `filename` defaults to the template's basename; `disposition` to attachment,
  # matching `send_data`.
  module Renderer
    DEFAULT_DISPOSITION = :attachment

    def self.install!
      ActionController::Renderers.add :pdf do |template, options|
        pdf = Typstify.render(
          template: template,
          data: options[:data],
          assigns: view_assigns
        )

        send_data(
          pdf,
          type: options[:type] || "application/pdf",
          filename: Typstify::Renderer.filename_for(template, options),
          disposition: options[:disposition] || DEFAULT_DISPOSITION,
          status: options[:status] || :ok
        )
      end
    end

    def self.filename_for(template, options)
      return options[:filename] if options[:filename]

      base = File.basename(template.to_s).sub(/\.typ(\.erb)?\z/, "")
      "#{base}.pdf"
    end
  end
end
