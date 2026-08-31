# frozen_string_literal: true

require "rails_helper"
require "generators/typstify/template/template_generator"

RSpec.describe Typstify::Generators::TemplateGenerator do
  let(:destination) { Pathname.new(Dir.mktmpdir("typstify-generator-")) }

  after { FileUtils.rm_rf(destination) }

  def run_generator(args)
    original = $stdout
    $stdout = StringIO.new
    described_class.start(args, destination_root: destination.to_s)
  ensure
    $stdout = original
  end

  described_class::AVAILABLE.each do |name|
    it "copies the #{name} template and its sample data" do
      run_generator([name])

      expect(destination.join("app/views/#{name}s/show.typ")).to exist
      expect(destination.join("app/views/#{name}s/sample_data.json")).to exist
    end
  end

  it "brings the shared branding partial along, since every template imports it" do
    run_generator(["invoice"])

    expect(destination.join("app/views/shared/branding.typ")).to exist
  end

  it "honours --path" do
    run_generator(["invoice", "--path", "billing/statement"])

    expect(destination.join("app/views/billing/statement.typ")).to exist
    expect(destination.join("app/views/billing/sample_data.json")).to exist
  end

  # Invoked directly rather than through .start, which is Thor's CLI entry point
  # and turns a Generators::Error into a printed message plus a non-zero exit.
  it "refuses a template that is not in the pack" do
    generator = described_class.new(["hologram"], [], destination_root: destination.to_s)

    expect { generator.invoke_all }
      .to raise_error(Rails::Generators::Error, /Unknown template "hologram".*invoice/m)
  end

  # The generated app should be able to render immediately, which is the whole
  # promise of the starter pack.
  it "produces a template that compiles against the generated branding" do
    run_generator(["invoice"])

    files = {
      "invoices/show.typ" => File.read(destination.join("app/views/invoices/show.typ"),
                                       encoding: Encoding::UTF_8),
      "shared/branding.typ" => File.read(destination.join("app/views/shared/branding.typ"),
                                         encoding: Encoding::UTF_8)
    }
    data = JSON.parse(File.read(destination.join("app/views/invoices/sample_data.json"),
                                encoding: Encoding::UTF_8))

    with_templates(files) do
      expect(Typstify.render(template: "invoices/show", data: data)).to start_with("%PDF-")
    end
  end
end
