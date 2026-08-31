# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typstify::Config do
  subject(:config) { described_class.new }

  it "defaults shared_dir to shared" do
    expect(config.shared_dir).to eq("shared")
  end

  it "always includes the bundled fonts on the search path" do
    expect(config.font_paths.map(&:to_s)).to include(Typstify.bundled_font_path.to_s)
  end

  it "keeps configured font paths ahead of the bundled ones" do
    config.font_paths = ["/srv/fonts"]

    expect(config.font_paths.map(&:to_s).first).to eq("/srv/fonts")
  end

  describe "#pdf_standards" do
    it "is empty by default" do
      expect(config.pdf_standards).to eq([])
    end

    it "maps :ua_1 to the compiler's flag" do
      config.pdf_standard = :ua_1

      expect(config.pdf_standards).to eq(["ua-1"])
    end

    it "accepts a string" do
      config.pdf_standard = "a_2b"

      expect(config.pdf_standards).to eq(["a-2b"])
    end

    it "rejects an unknown standard by name, listing the valid ones" do
      config.pdf_standard = :pdf_ua

      expect { config.pdf_standards }.to raise_error(ArgumentError, /Unknown pdf_standard :pdf_ua.*:ua_1/m)
    end
  end

  describe "#strict_fonts" do
    it "is on outside Rails" do
      expect(config.strict_fonts).to be(true)
    end

    it "can be turned off" do
      config.strict_fonts = false

      expect(config.strict_fonts).to be(false)
    end
  end
end
