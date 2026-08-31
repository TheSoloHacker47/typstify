# frozen_string_literal: true

require "json"
require "pathname"
require "tmpdir"
require "fileutils"

# Helpers shared by the unit and security specs: a throwaway template root you
# can write .typ files into, and PDF text extraction.
module Fixtures
  GEM_ROOT = Pathname.new(__dir__).join("..", "..").expand_path

  # Build a template root in a tmpdir, yield it, clean up.
  #
  #   with_templates("invoices/show.typ" => "= Hi") do |root|
  #     Typstify.render(template: "invoices/show")
  #   end
  def with_templates(files)
    Dir.mktmpdir("typstify-spec-") do |dir|
      root = Pathname.new(dir)
      files.each do |name, contents|
        path = root.join(name)
        FileUtils.mkdir_p(path.dirname)
        File.write(path, contents, encoding: Encoding::UTF_8)
      end
      Typstify.configure do |c|
        c.template_root = root
        c.strict_fonts = false
      end

      yield root
    end
  end

  # Text of every page, whitespace-normalised, as one string.
  def pdf_text(bytes)
    require "pdf-reader"
    Dir.mktmpdir do |dir|
      path = File.join(dir, "out.pdf")
      File.binwrite(path, bytes)
      PDF::Reader.new(path).pages.map(&:text).join("\n").gsub(/[ \t]+/, " ")
    end
  end

  def pdf_page_count(bytes)
    require "pdf-reader"
    Dir.mktmpdir do |dir|
      path = File.join(dir, "out.pdf")
      File.binwrite(path, bytes)
      PDF::Reader.new(path).page_count
    end
  end

  def starter_sample_data(name)
    JSON.parse(File.read(GEM_ROOT.join("templates", name, "sample_data.json"), encoding: Encoding::UTF_8))
  end
end

RSpec.configure { |config| config.include Fixtures }
