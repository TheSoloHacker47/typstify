# frozen_string_literal: true

require "spec_helper"

# The escape table is a security boundary for ERB mode, so every character in
# it gets its own example rather than one round-trip assertion. If a character
# is ever dropped from SIGNIFICANT, exactly one example fails and names it.
RSpec.describe Typstify::Escaping do
  describe ".typ" do
    Typstify::Escaping::SIGNIFICANT.each do |char|
      it "escapes #{char.inspect}" do
        expect(described_class.typ("a#{char}b")).to eq("a\\#{char}b")
      end
    end

    it "escapes a backslash exactly once, not twice" do
      expect(described_class.typ('a\b')).to eq('a\\\\b')
    end

    it "leaves ordinary text alone" do
      expect(described_class.typ("Ada Okonkwo, Dublin")).to eq("Ada Okonkwo, Dublin")
    end

    it "handles nil and numbers by way of to_s" do
      expect(described_class.typ(nil)).to eq("")
      expect(described_class.typ(42)).to eq("42")
    end

    it "neutralises a whole injected expression" do
      expect(described_class.typ('#read("/etc/passwd")')).to eq('\\#read("/etc/passwd")'.sub('"', '\\"').sub(
                                                                  /"\)$/, '\\")'
                                                                ))
    end
  end

  describe "round-tripping through the compiler" do
    it "renders every significant character literally" do
      hostile = %q{#read("/etc/passwd") *bold* _em_ [block] $math$ @pkg <label> `raw` \ "quoted"}

      with_templates("probe.typ" => "Value: #{described_class.typ(hostile)}") do
        text = pdf_text(Typstify.render(template: "probe"))
        expect(text).to include(hostile)
      end
    end
  end
end
