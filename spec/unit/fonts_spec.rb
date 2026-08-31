# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typstify::Fonts do
  describe ".declared_families" do
    it "reads a single family" do
      expect(described_class.declared_families('#set text(font: "Inter")')).to eq(["Inter"])
    end

    it "reads a fallback list" do
      source = '#text(font: ("Inter", "Noto Sans"))[hi]'

      expect(described_class.declared_families(source)).to eq(["Inter", "Noto Sans"])
    end

    it "de-duplicates repeated families" do
      source = %(#set text(font: "Inter")\n#text(font: "Inter")[x])

      expect(described_class.declared_families(source)).to eq(["Inter"])
    end

    it "finds nothing when no font is named" do
      expect(described_class.declared_families("= Just a heading")).to be_empty
    end
  end

  describe ".read_families" do
    it "reads the family name out of a bundled TTF" do
      path = Typstify.bundled_font_path.join("inter", "Inter-Regular.ttf")

      expect(described_class.read_families(path.to_s)).to include("Inter")
    end

    it "returns nothing for a file that is not a font" do
      expect(described_class.read_families(__FILE__)).to be_empty
    end
  end

  describe ".missing" do
    it "resolves the bundled Inter with no configuration" do
      expect(described_class.missing('#set text(font: "Inter")', Typstify.config.font_paths)).to be_empty
    end

    it "treats the compiler's embedded faces as available" do
      source = '#set text(font: "New Computer Modern")'

      expect(described_class.missing(source, Typstify.config.font_paths)).to be_empty
    end

    it "reports a family nothing can supply" do
      source = '#set text(font: "Definitely Not Installed XYZ")'

      expect(described_class.missing(source, Typstify.config.font_paths))
        .to eq(["Definitely Not Installed XYZ"])
    end
  end

  # T8. The compiler warns and silently substitutes; we would rather stop.
  describe "strict_fonts at render time" do
    let(:template) do
      { "probe.typ" => %(#set text(font: "Definitely Not Installed XYZ")\n= Hi) }
    end

    it "raises FontMissingError in strict mode" do
      with_templates(template) do
        Typstify.config.strict_fonts = true

        expect { Typstify.render(template: "probe") }
          .to raise_error(Typstify::FontMissingError, /Definitely Not Installed XYZ/)
      end
    end

    it "names the directories it searched" do
      with_templates(template) do
        Typstify.config.strict_fonts = true

        expect { Typstify.render(template: "probe") }
          .to raise_error(Typstify::FontMissingError, /#{Regexp.escape(Typstify.bundled_font_path.to_s)}/)
      end
    end

    it "warns and renders anyway when strict mode is off" do
      seen = []

      with_templates(template) do
        Typstify.config.strict_fonts = false
        Typstify.config.on_warning = ->(warnings, _template) { seen.concat(warnings) }

        expect(Typstify.render(template: "probe")).to start_with("%PDF-")
      end

      expect(seen.first).to include('unknown font family: "Definitely Not Installed XYZ"')
    end

    it "also checks families declared in shared partials" do
      files = {
        "probe.typ" => %(#import "shared/brand.typ": *\n#show: brand\n= Hi),
        "shared/brand.typ" => %(#let brand(body) = {\n  set text(font: "Another Missing Face")\n  body\n})
      }

      with_templates(files) do
        Typstify.config.strict_fonts = true

        expect { Typstify.render(template: "probe") }
          .to raise_error(Typstify::FontMissingError, /Another Missing Face/)
      end
    end
  end
end
