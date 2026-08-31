# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typstify::Resolver do
  it "finds a .typ template" do
    with_templates("invoices/show.typ" => "= Hi") do
      resolution = described_class.new.call("invoices/show")

      expect(resolution.mode).to eq(:data)
      expect(resolution.erb?).to be(false)
    end
  end

  it "falls back to .typ.erb" do
    with_templates("invoices/show.typ.erb" => "= Hi") do
      expect(described_class.new.call("invoices/show").mode).to eq(:erb)
    end
  end

  # Data mode is the blessed default, so it wins a tie.
  it "prefers .typ over .typ.erb when both exist" do
    with_templates("invoices/show.typ" => "= data", "invoices/show.typ.erb" => "= erb") do
      expect(described_class.new.call("invoices/show").mode).to eq(:data)
    end
  end

  it "accepts a name that already carries its extension" do
    with_templates("invoices/show.typ" => "= Hi") do
      expect(described_class.new.call("invoices/show.typ").name).to eq("invoices/show")
    end
  end

  # T11
  it "lists both paths it tried when nothing is there" do
    with_templates("invoices/show.typ" => "= Hi") do
      expect { described_class.new.call("invoices/nope") }
        .to raise_error(Typstify::MissingTemplate, %r{invoices/nope\.typ\b.*invoices/nope\.typ\.erb}m)
    end
  end

  # T4
  it "refuses to escape template_root with .." do
    with_templates("invoices/show.typ" => "= Hi") do
      expect { described_class.new.call("../../etc/passwd") }
        .to raise_error(Typstify::PathError, /outside template_root/)
    end
  end

  it "refuses an absolute path" do
    with_templates("invoices/show.typ" => "= Hi") do
      expect { described_class.new.call("/etc/passwd") }
        .to raise_error(Typstify::PathError, /must be relative/)
    end
  end

  it "allows .. that stays inside the root" do
    with_templates("invoices/show.typ" => "= Hi") do
      expect(described_class.new.call("reports/../invoices/show").mode).to eq(:data)
    end
  end
end
