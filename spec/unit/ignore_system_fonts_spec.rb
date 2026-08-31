# frozen_string_literal: true

require "spec_helper"

# The system-font scan is the dominant cost of a render (roughly 50 ms of a
# 58 ms invoice on an M-series Mac). Skipping it is a real production setting,
# so the font check has to agree with the compiler about what is available.
RSpec.describe "ignore_system_fonts" do
  let(:system_family) do
    Typstify::Fonts.families_in("/System/Library/Fonts").first ||
      Typstify::Fonts.families_in("/usr/share/fonts").first
  end

  it "still resolves the bundled fonts" do
    expect(Typstify::Fonts.missing('#set text(font: "Inter")', Typstify.config.font_paths,
                                   include_system: false)).to be_empty
  end

  it "still resolves the compiler's embedded faces" do
    expect(Typstify::Fonts.missing('#set text(font: "New Computer Modern")',
                                   Typstify.config.font_paths, include_system: false)).to be_empty
  end

  it "drops the system directories from the search path" do
    with_system = Typstify::Fonts.search_paths(Typstify.config.font_paths)
    without = Typstify::Fonts.search_paths(Typstify.config.font_paths, include_system: false)

    expect(without.size).to be < with_system.size
    expect(without).to eq(Typstify.config.font_paths.map { |p| File.expand_path(p.to_s) })
  end

  it "reports a system font as missing once the system is out of scope" do
    skip "no system fonts on this machine" if system_family.nil?

    expect(Typstify::Fonts.missing(%(#set text(font: "#{system_family}")),
                                   Typstify.config.font_paths, include_system: false))
      .to eq([system_family])
  end

  it "renders with only the vendored fonts" do
    with_templates("probe.typ" => %(#set text(font: "Inter")\n= Vendored only)) do
      Typstify.config.ignore_system_fonts = true
      Typstify.config.strict_fonts = true

      expect(pdf_text(Typstify.render(template: "probe"))).to include("Vendored only")
    end
  end

  it "refuses a system font in strict mode when the system is out of scope" do
    skip "no system fonts on this machine" if system_family.nil?

    with_templates("probe.typ" => %(#set text(font: "#{system_family}")\n= Hi)) do
      Typstify.config.ignore_system_fonts = true
      Typstify.config.strict_fonts = true

      expect { Typstify.render(template: "probe") }.to raise_error(Typstify::FontMissingError)
    end
  end
end
