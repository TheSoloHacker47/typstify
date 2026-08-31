# frozen_string_literal: true

require "rails_helper"
require "generators/typstify/install/install_generator"

RSpec.describe Typstify::Generators::InstallGenerator do
  let(:destination) { Pathname.new(Dir.mktmpdir("typstify-generator-")) }

  after { FileUtils.rm_rf(destination) }

  def run_generator(args = [])
    capture_generator_output do
      described_class.start(args, destination_root: destination.to_s)
    end
  end

  def capture_generator_output
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  it "writes the initializer" do
    run_generator

    expect(destination.join("config/initializers/typstify.rb")).to exist
  end

  it "documents every configuration option in the initializer" do
    run_generator
    initializer = File.read(destination.join("config/initializers/typstify.rb"), encoding: Encoding::UTF_8)

    expect(initializer).to include("template_root", "shared_dir", "font_paths",
                                   "package_cache", "pdf_standard", "strict_fonts", "on_warning")
  end

  it "writes the shared branding partial" do
    run_generator

    expect(destination.join("app/views/shared/branding.typ")).to exist
  end

  it "writes a branding partial the compiler accepts" do
    run_generator

    files = {
      "probe.typ" => %(#import "shared/branding.typ": *\n#show: brand-page\n#brand-header(title: "Hi")),
      "shared/branding.typ" => File.read(destination.join("app/views/shared/branding.typ"),
                                         encoding: Encoding::UTF_8)
    }

    with_templates(files) do
      expect(Typstify.render(template: "probe")).to start_with("%PDF-")
    end
  end
end
