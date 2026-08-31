# frozen_string_literal: true

# rake goldens — regenerate the golden text the template specs compare against.
# Review the diff before committing it; that review is the whole point.

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require_relative "golden"
require "fileutils"

FileUtils.mkdir_p(Golden::DIR)

Golden::TEMPLATES.each do |name|
  text = Golden.extract(Golden.render(name))
  Golden.write(name, text)
  puts "wrote #{Golden.path(name).relative_path_from(Golden::GEM_ROOT)} (#{text.lines.size} lines)"
end
