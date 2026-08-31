# frozen_string_literal: true

require "erb"

module Typstify
  # ERB mode: `.typ.erb` templates are ordinary ERB whose *output* is Typst
  # source. Provided for teams migrating from wicked_pdf who want their existing
  # view habits; data mode is the one to reach for.
  #
  # The distinction that matters: in data mode a user string is data all the way
  # down and cannot change the document. Here it is spliced into source, so
  # every dynamic value must go through `typ()`. That is not a style preference
  # — an unescaped value is code injection.
  module ErbPipeline
    # The object templates are evaluated against. Deliberately small: `typ`,
    # `data`, and whatever instance variables the controller had.
    class Context
      def initialize(data:, assigns: {})
        @data = data
        assigns.each { |name, value| instance_variable_set(:"@#{name}", value) }
      end

      # The data hash passed to `render pdf:` / `Typstify.render`.
      attr_reader :data

      # Escape a value so Typst renders it literally. See Typstify::Escaping.
      def typ(value)
        Escaping.typ(value)
      end

      def template_binding
        binding
      end
    end

    module_function

    # @return [String] Typst source
    def render(source, data: nil, assigns: {})
      context = Context.new(data: data, assigns: assigns)
      ERB.new(source, trim_mode: "-").result(context.template_binding)
    end
  end
end
