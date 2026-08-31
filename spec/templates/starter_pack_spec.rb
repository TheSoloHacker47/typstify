# frozen_string_literal: true

require "spec_helper"
require_relative "../support/golden"

# T6 — the starter pack is the marketing surface, so it has to compile in CI
# with its own sample data, on every supported Ruby and Rails.
RSpec.describe "starter templates" do
  Golden::TEMPLATES.each do |name|
    describe name do
      let(:pdf) { Golden.render(name) }

      it "compiles with its sample data" do
        expect(pdf).to start_with("%PDF-")
      end

      it "resolves every font it names, with no configuration" do
        # Golden.render sets strict_fonts, so a missing family raises rather
        # than silently substituting. Inter ships with the gem for this reason.
        expect { pdf }.not_to raise_error
      end

      it "matches its golden text" do
        expect(Golden.extract(pdf)).to eq(Golden.read(name))
      end
    end
  end

  describe "invoice" do
    it "renders the numbers it was given" do
      text = Golden.extract(Golden.render("invoice"))

      expect(text).to include("INV-2043").and include("$4,860.00").and include("Northwind Trading Ltd.")
    end

    it "fits a four-line invoice on one page" do
      expect(Golden.extract(Golden.render("invoice"))).to start_with("pages: 1")
    end
  end

  describe "certificate" do
    it "is landscape and names its recipient" do
      expect(Golden.extract(Golden.render("certificate"))).to include("Ada Okonkwo")
    end
  end

  describe "report" do
    it "renders metrics, a table and prose" do
      text = Golden.extract(Golden.render("report"))

      expect(text).to include("48.2M").and include("Checkout API").and include("Actions for next month")
    end
  end

  describe "every template" do
    it "imports the shared branding partial, so rebranding is one edit" do
      Golden::TEMPLATES.each do |name|
        source = File.read(Golden::GEM_ROOT.join("templates", name, "#{name}.typ"), encoding: Encoding::UTF_8)

        expect(source).to include(%(#import "shared/branding.typ"))
      end
    end

    it "ships sample data for the preview task" do
      Golden::TEMPLATES.each do |name|
        expect(Golden::GEM_ROOT.join("templates", name, "sample_data.json")).to exist
      end
    end
  end
end
