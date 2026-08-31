# frozen_string_literal: true

require "json"
require "pathname"
require "fileutils"
require "tmpdir"

# Shared by the template-pack specs and the `rake goldens` task.
#
# Goldens are extracted *text*, not PDF bytes. Typst stamps /CreationDate into
# every document, so byte-identical output is impossible across runs — and a
# binary golden is unreviewable anyway. A text diff is something a human can
# actually read in a pull request, which is the point of having goldens.
module Golden
  GEM_ROOT = Pathname.new(__dir__).join("..", "..").expand_path
  DIR = GEM_ROOT.join("spec", "goldens")
  TEMPLATES = %w[invoice receipt report certificate].freeze

  module_function

  def render(name)
    require "typstify"

    Dir.mktmpdir("typstify-golden-") do |dir|
      root = Pathname.new(dir)
      FileUtils.mkdir_p(root.join(name))
      FileUtils.mkdir_p(root.join("shared"))
      FileUtils.cp(GEM_ROOT.join("templates", name, "#{name}.typ"), root.join(name, "show.typ"))
      FileUtils.cp(GEM_ROOT.join("templates", "shared", "branding.typ"), root.join("shared", "branding.typ"))

      Typstify.configure do |c|
        c.template_root = root
        c.strict_fonts = true
      end

      Typstify.render(template: "#{name}/show", data: sample_data(name))
    end
  end

  def sample_data(name)
    JSON.parse(File.read(GEM_ROOT.join("templates", name, "sample_data.json"), encoding: Encoding::UTF_8))
  end

  def extract(pdf_bytes)
    require "pdf-reader"

    Dir.mktmpdir do |dir|
      path = File.join(dir, "golden.pdf")
      File.binwrite(path, pdf_bytes)
      reader = PDF::Reader.new(path)
      pages = reader.pages.map { |page| page.text.gsub(/[ \t]+/, " ").strip }
      "pages: #{reader.page_count}\n\n#{pages.join("\n\n--- page break ---\n\n")}\n"
    end
  end

  def path(name)
    DIR.join("#{name}.txt")
  end

  def read(name)
    File.read(path(name), encoding: Encoding::UTF_8)
  end

  def write(name, text)
    File.write(path(name), text, encoding: Encoding::UTF_8)
  end
end
