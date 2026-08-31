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

    # No `rake_tasks do load … end` here: Rails::Engine already loads every
    # .rake file under the engine's lib/tasks. Loading it again re-opens the
    # task and Rake *appends* the second body, so `typstify:preview` would
    # render — and announce — the same PDF twice.
  end
end
