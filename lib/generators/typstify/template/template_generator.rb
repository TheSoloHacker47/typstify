# frozen_string_literal: true

require "rails/generators"

module Typstify
  module Generators
    # rails g typstify:template invoice
    #
    # Copies a starter template and its sample data into app/views, so the
    # preview task works immediately and you have something real to edit.
    class TemplateGenerator < ::Rails::Generators::NamedBase
      AVAILABLE = %w[invoice receipt report certificate].freeze

      source_root File.expand_path("templates", __dir__)

      class_option :path, type: :string, default: nil,
                          desc: "Where to put it, e.g. billing/invoice (default: <plural>/show)"

      desc "Copies a starter template (#{AVAILABLE.join(", ")}) into app/views"

      def validate_name
        return if AVAILABLE.include?(name)

        raise ::Rails::Generators::Error,
              "Unknown template #{name.inspect}. Available: #{AVAILABLE.join(", ")}"
      end

      def copy_template
        copy_file source_dir.join("#{name}.typ").to_s, "app/views/#{destination}.typ"
      end

      def copy_sample_data
        copy_file source_dir.join("sample_data.json").to_s,
                  "app/views/#{File.dirname(destination)}/sample_data.json"
      end

      def ensure_branding
        return if File.exist?(File.join(destination_root, "app/views/shared/branding.typ"))

        copy_file Typstify.template_pack_path.join("shared", "branding.typ").to_s,
                  "app/views/shared/branding.typ"
      end

      def report
        say ""
        say "Preview it:  rake typstify:preview[#{destination}]", :green
        say ""
        say "Render it from a controller:"
        say ""
        say "    render pdf: #{destination.inspect},"
        say "           data: { ... },"
        say "           filename: #{"#{name}.pdf".inspect}"
        say ""
      end

      private

      def destination
        @destination ||= begin
          given = options[:path]
          given.nil? || given.empty? ? "#{name}s/show" : given
        end
      end

      def source_dir
        Typstify.template_pack_path.join(name)
      end
    end
  end
end
