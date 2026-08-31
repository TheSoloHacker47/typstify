# frozen_string_literal: true

require "rails/engine"

module Typstify
  # Wires the gem into a Rails application: the `pdf` renderer, sensible
  # defaults taken from the app, and the rake tasks.
  class Engine < ::Rails::Engine
    isolate_namespace Typstify

    # Generators live in this gem, not the host app.
    config.app_generators.templates.unshift(File.expand_path("../generators", __dir__))

    initializer "typstify.renderer" do
      ActiveSupport.on_load(:action_controller) do
        require "typstify/renderer"
        Typstify::Renderer.install!
      end
    end

    initializer "typstify.defaults" do |app|
      unless Typstify.config.instance_variable_get(:@template_root)
        Typstify.config.template_root = app.root.join("app/views")
      end
    end

    # Applied after the host's initializers have had their say, so a
    # package_cache set in config/initializers/typstify.rb is honoured.
    config.after_initialize do
      Typstify.apply_package_cache!
    end

    rake_tasks do
      load File.expand_path("../tasks/typstify.rake", __dir__)
    end
  end
end
