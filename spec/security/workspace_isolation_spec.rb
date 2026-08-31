# frozen_string_literal: true

require "spec_helper"

# T4 — what a template may import, and what it may not reach.
RSpec.describe "workspace isolation" do
  it "resolves shared imports from a view subdirectory" do
    files = {
      "invoices/show.typ" => %(#import "shared/branding.typ": brand-header\n#brand-header(title: "Invoice")),
      "shared/branding.typ" => %(#let brand-header(title: "") = text(size: 18pt)[#title])
    }

    with_templates(files) do
      expect(pdf_text(Typstify.render(template: "invoices/show"))).to include("Invoice")
    end
  end

  it "resolves shared imports nested inside the shared directory" do
    files = {
      "invoices/show.typ" => %(#import "shared/theme/colors.typ": accent\n#text(fill: accent)[Hi]),
      "shared/theme/colors.typ" => %(#let accent = rgb("#1f5eff"))
    }

    with_templates(files) do
      expect(pdf_text(Typstify.render(template: "invoices/show"))).to include("Hi")
    end
  end

  it "refuses a template name that climbs out of template_root" do
    with_templates("invoices/show.typ" => "= Hi") do
      expect { Typstify.render(template: "../../../../etc/passwd") }
        .to raise_error(Typstify::PathError, /outside template_root/)
    end
  end

  it "refuses an absolute template name" do
    with_templates("invoices/show.typ" => "= Hi") do
      expect { Typstify.render(template: "/etc/passwd") }
        .to raise_error(Typstify::PathError, /must be relative/)
    end
  end

  it "cannot import a view that was not copied into the workspace" do
    files = {
      "invoices/show.typ" => %(#import "../secrets/keys.typ": key\n#key),
      "secrets/keys.typ" => %(#let key = "AKIA-SUPER-SECRET")
    }

    with_templates(files) do
      expect { Typstify.render(template: "invoices/show") }.to raise_error(Typstify::CompileError)
    end
  end

  it "leaves nothing behind on disk" do
    before = Dir.glob(File.join(Dir.tmpdir, "typstify-*")).size

    with_templates("probe.typ" => "= Hi") { Typstify.render(template: "probe") }

    expect(Dir.glob(File.join(Dir.tmpdir, "typstify-*")).size).to eq(before)
  end
end
