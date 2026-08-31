# frozen_string_literal: true

require "spec_helper"

# T9 — Typst Universe packages, vendored, with no network.
#
# The binding resolves packages through the platform data directory (see
# ext/typst/src/package.rs upstream). On Linux — which is to say, in every
# Docker image — that directory is XDG_DATA_HOME, so pointing it at a vendored
# tree is what makes an offline build work. macOS uses a fixed location that no
# environment variable steers, so these examples only run where the mechanism
# exists. docs/fonts-and-docker.md says the same thing to users.
RSpec.describe "vendored Typst packages", skip: (RUBY_PLATFORM.include?("linux") ? false : "Linux only: macOS ignores XDG_DATA_HOME") do
  let(:vendored) { Pathname.new(__dir__).join("..", "fixtures", "typst_packages").expand_path }
  let(:template) do
    { "probe.typ" => %(#import "@local/typstify-fixture:0.1.0": vendored-badge\n#vendored-badge("ok")) }
  end

  around do |example|
    previous = ENV.fetch("XDG_DATA_HOME", nil)
    example.run
    ENV["XDG_DATA_HOME"] = previous
  end

  it "compiles an import from the configured package_cache" do
    with_templates(template) do
      Typstify.configure { |c| c.package_cache = vendored }

      expect(pdf_text(Typstify.render(template: "probe"))).to include("Vendored: ok")
    end
  end

  it "exports the cache directory as XDG_DATA_HOME" do
    Typstify.configure { |c| c.package_cache = vendored }

    expect(ENV.fetch("XDG_DATA_HOME")).to eq(vendored.to_s)
  end

  it "leaves the environment alone when no cache is configured" do
    ENV["XDG_DATA_HOME"] = "/tmp/untouched"
    Typstify.configure { |c| c.template_root = Dir.pwd }

    expect(ENV.fetch("XDG_DATA_HOME")).to eq("/tmp/untouched")
  end
end
