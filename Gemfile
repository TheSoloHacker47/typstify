# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Rails 8.1's actionview calls `yield(*, **)` inside a block, which only parses
# on Ruby 3.4+ even though the gem declares `required_ruby_version >= 3.2`.
# Local development on an older Ruby therefore resolves below 8.1; CI pairs
# Rails 8.1 with Ruby 3.4 explicitly.
rails_requirement =
  if (version = ENV.fetch("RAILS_VERSION", nil))
    ["~> #{version}"]
  elsif Gem::Version.new(RUBY_VERSION) < Gem::Version.new("3.4")
    [">= 7.1", "< 8.1"]
  else
    [">= 7.1"]
  end

gem "rails", *rails_requirement

group :development, :test do
  gem "pdf-reader", "~> 2.12"
  gem "rake", "~> 13.0"
  gem "rspec-rails", "~> 7.0"
  gem "rubocop", "~> 1.66"
  gem "rubocop-rspec", "~> 3.0"
  gem "simplecov", "~> 0.22", require: false
  gem "sqlite3", ">= 1.4"
end
