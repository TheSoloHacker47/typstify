# frozen_string_literal: true

# rake previews — render every starter template to PNG so a human can look at
# them. Not part of the suite; design review is not something a spec can do.

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require_relative "golden"
require "typst"
require "fileutils"

out = Golden::GEM_ROOT.join("spec", "tmp", "previews")
FileUtils.mkdir_p(out)

Golden::TEMPLATES.each do |name|
  Dir.mktmpdir("typstify-preview-") do |dir|
    root = Pathname.new(dir)
    FileUtils.mkdir_p(root.join("shared"))
    FileUtils.cp(Golden::GEM_ROOT.join("templates", name, "#{name}.typ"), root.join("main.typ"))
    FileUtils.cp(Golden::GEM_ROOT.join("templates", "shared", "branding.typ"), root.join("shared", "branding.typ"))
    File.write(root.join("data.json"), JSON.pretty_generate(Golden.sample_data(name)))

    document = Typst(
      root.join("main.typ").to_s,
      root: root.to_s,
      font_paths: [Golden::GEM_ROOT.join("fonts").to_s]
    ).compile(:png, ppi: 110)

    document.pages.each_with_index do |page, index|
      path = out.join("#{name}-#{index + 1}.png")
      path.binwrite(page)
      puts "wrote #{path.relative_path_from(Golden::GEM_ROOT)}"
    end
  end
end
