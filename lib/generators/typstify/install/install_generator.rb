# frozen_string_literal: true

require "rails/generators"

module Typstify
  module Generators
    # rails g typstify:install
    #
    # Drops in the initializer and the shared branding partial every starter
    # template imports.
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates config/initializers/typstify.rb and app/views/shared/branding.typ"

      def create_initializer
        template "typstify.rb", "config/initializers/typstify.rb"
      end

      def create_branding
        copy_file Typstify.template_pack_path.join("shared", "branding.typ").to_s,
                  "app/views/shared/branding.typ"
      end

      def report
        say ""
        say "Typstify installed.", :green
        say ""
        say "  Next:  rails g typstify:template invoice"
        say "         rake typstify:preview[invoices/show]"
        say ""
        say "  Fonts: templates use Inter, which ships with the gem. To use your own,"
        say "         vendor the files and set c.font_paths in the initializer."
        say "         See https://github.com/TheSoloHacker47/typstify/blob/main/docs/fonts-and-docker.md"
        say ""
      end
    end
  end
end
