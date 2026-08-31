# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "active_record/railtie"
require "active_storage/engine"

require "typstify"
# Explicit because the spec suite loads the gem before Rails exists (unit specs
# run with no Rails at all). A real application requires Rails first, so
# lib/typstify.rb picks the engine up on its own.
require "typstify/engine"

module Dummy
  # The smallest Rails application that can exercise a renderer: controllers,
  # ActiveRecord (for ActiveStorage), and nothing else. Deliberately a real app
  # rather than a stub, because `render pdf:` has to work through the real
  # renderer registration across four Rails versions.
  class Application < Rails::Application
    config.load_defaults 7.1
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.consider_all_requests_local = true
    # Let exceptions reach the specs instead of becoming a 500 page: the error
    # classes this gem raises are part of its contract.
    config.action_dispatch.show_exceptions = :none
    config.secret_key_base = "typstify-dummy-secret-key-base-for-specs-only"
    config.logger = Logger.new(IO::NULL)
    config.active_storage.service = :test
    if config.active_support.respond_to?(:to_time_preserves_timezone=)
      config.active_support.to_time_preserves_timezone = :zone
    end
    config.hosts.clear
  end
end
