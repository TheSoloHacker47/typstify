# frozen_string_literal: true

require "spec_helper"

# The `typst` binding discarded warnings from a *successful* compile until
# 0.15.1.6 (actsasflinn/typst-rb#10, merged upstream). This gem therefore has
# to work both ways: forward real compiler warnings where they exist, and fall
# back to its own font check where they do not.
RSpec.describe "compiler warnings" do
  # Stands in for Typst::PdfDocument on either side of that change.
  def fake_document(warnings)
    Class.new do
      def initialize(warnings) = @warnings = warnings
      attr_reader :warnings
    end.new(warnings)
  end

  def document_without_warnings
    Class.new { def pages = ["%PDF-"] }.new
  end

  describe ".warnings_supported?" do
    it "answers by capability rather than by version string" do
      expect(Typstify::Adapter.warnings_supported?)
        .to eq(Typst::Document.method_defined?(:warnings))
    end

    it "is memoised, and the cache is cleared by reset!" do
      allow(Typst::Document).to receive(:method_defined?).with(:warnings).and_return(true)
      expect(Typstify::Adapter.warnings_supported?).to be(true)

      Typstify.reset!
      allow(Typst::Document).to receive(:method_defined?).with(:warnings).and_return(false)

      expect(Typstify::Adapter.warnings_supported?).to be(false)
    end
  end

  describe ".dispatch_warnings" do
    let(:seen) { [] }
    let(:config) do
      Typstify::Config.new.tap { |c| c.on_warning = ->(warnings, template) { seen << [warnings, template] } }
    end
    let(:raw) do
      <<~WARNING
        warning: unknown font family: "Inter"
          ┌─ /tmp/typstify-abc/main.typ:3:22
          │
      WARNING
    end

    it "forwards a compiler warning through on_warning" do
      Typstify::Adapter.dispatch_warnings(fake_document([raw]), root: "/tmp/typstify-abc",
                                                                template: "invoices/show", config: config)

      expect(seen).to eq([[['unknown font family: "Inter" (line 3)'], "invoices/show"]])
    end

    it "names the developer's template, not the workspace" do
      Typstify::Adapter.dispatch_warnings(fake_document([raw]), root: "/tmp/typstify-abc",
                                                                template: "invoices/show", config: config)

      expect(seen.join).not_to include("typstify-abc")
    end

    it "forwards several warnings in one call" do
      Typstify::Adapter.dispatch_warnings(fake_document([raw, raw]), root: "/tmp/typstify-abc",
                                                                     template: "x", config: config)

      expect(seen.first.first.size).to eq(2)
    end

    it "stays quiet when the compile produced none" do
      Typstify::Adapter.dispatch_warnings(fake_document([]), root: "/tmp/x", template: "x", config: config)

      expect(seen).to be_empty
    end

    # The path older bindings take.
    it "stays quiet when the document cannot report warnings at all" do
      Typstify::Adapter.dispatch_warnings(document_without_warnings, root: "/tmp/x",
                                                                     template: "x", config: config)

      expect(seen).to be_empty
    end
  end

  describe "the font pre-check, once the compiler can speak for itself" do
    let(:seen) { [] }
    let(:template) { { "probe.typ" => %(#set text(font: "Definitely Not Installed XYZ")\n= Hi) } }

    it "defers to the compiler rather than saying the same thing twice" do
      allow(Typstify::Adapter).to receive(:warnings_supported?).and_return(true)

      with_templates(template) do
        Typstify.config.strict_fonts = false
        Typstify.config.on_warning = ->(warnings, _t) { seen.concat(warnings) }
        Typstify.render(template: "probe")
      end

      expect(seen).to be_empty
    end

    it "still warns on a binding that cannot" do
      allow(Typstify::Adapter).to receive(:warnings_supported?).and_return(false)

      with_templates(template) do
        Typstify.config.strict_fonts = false
        Typstify.config.on_warning = ->(warnings, _t) { seen.concat(warnings) }
        Typstify.render(template: "probe")
      end

      expect(seen.first).to include("unknown font family")
    end

    # Strict mode is the reason to keep the pre-check at all: it fails before
    # the compiler runs, rather than reporting after the fact.
    it "still raises in strict mode either way" do
      allow(Typstify::Adapter).to receive(:warnings_supported?).and_return(true)

      with_templates(template) do
        Typstify.config.strict_fonts = true

        expect { Typstify.render(template: "probe") }.to raise_error(Typstify::FontMissingError)
      end
    end

    it "lists only the directories the compiler will actually search" do
      with_templates(template) do
        Typstify.config.strict_fonts = true
        Typstify.config.ignore_system_fonts = true

        expect { Typstify.render(template: "probe") }
          .to raise_error(Typstify::FontMissingError, %r{\A(?!.*/System/Library/Fonts).*\z}m)
      end
    end
  end
end
