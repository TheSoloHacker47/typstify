# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # RuboCop is a development dependency; ignore when it is absent.
end

desc "Regenerate the golden PDFs the template specs compare against"
task :goldens do
  ruby "spec/support/regenerate_goldens.rb"
end

desc "Render every starter template to spec/tmp/previews as PNG, for eyeballing"
task :previews do
  ruby "spec/support/render_previews.rb"
end

task default: %i[spec rubocop]
