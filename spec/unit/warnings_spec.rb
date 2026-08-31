# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typstify::Warnings do
  let(:raw) do
    <<~DIAGNOSTIC
      warning: unknown font family: "Inter"
        ┌─ /tmp/typstify-abc/main.typ:3:1
        │
      error: expected expression
        ┌─ /tmp/typstify-abc/main.typ:12:8
        │
    DIAGNOSTIC
  end

  describe ".parse" do
    it "splits errors and warnings, keeping their locations" do
      diagnostics = described_class.parse(raw)

      expect(diagnostics.map(&:severity)).to eq(%i[warning error])
      expect(diagnostics.first.message).to eq('unknown font family: "Inter"')
      expect(diagnostics.last.line).to eq(12)
      expect(diagnostics.last.column).to eq(8)
    end

    it "returns nothing for text with no diagnostics" do
      expect(described_class.parse("all fine")).to be_empty
    end
  end

  describe ".rewrite_paths" do
    it "replaces the tmpdir with the developer's template name" do
      rewritten = described_class.rewrite_paths(raw, "/tmp/typstify-abc", "invoices/show")

      expect(rewritten).to include("invoices/show.typ:12:8")
      expect(rewritten).not_to include("typstify-abc")
    end
  end

  describe ".dispatch" do
    it "passes only warnings to the hook" do
      seen = []
      config = Typstify::Config.new
      config.on_warning = ->(warnings, template) { seen << [warnings, template] }

      described_class.dispatch(described_class.parse(raw), "invoices/show", config)

      expect(seen).to eq([[['unknown font family: "Inter" (line 3)'], "invoices/show"]])
    end

    it "stays quiet when there are no warnings" do
      seen = []
      config = Typstify::Config.new
      config.on_warning = ->(*args) { seen << args }

      described_class.dispatch(described_class.parse("error: nope"), "x", config)

      expect(seen).to be_empty
    end
  end
end
