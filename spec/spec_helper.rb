# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/gemfiles/"
  enable_coverage :line
end

ENV["RAILS_ENV"] = "test"

require "typstify"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.before do
    Typstify.reset!
  end

  config.after do
    Typstify.reset!
  end
end

require_relative "support/fixtures"
