# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typstify::Data do
  describe ".dump" do
    it "serialises nested structures with symbol keys" do
      json = JSON.parse(described_class.dump({ number: "A-1", items: [{ qty: 2 }] }))

      expect(json).to eq("number" => "A-1", "items" => [{ "qty" => 2 }])
    end

    it "stringifies symbol values" do
      expect(JSON.parse(described_class.dump({ state: :paid }))).to eq("state" => "paid")
    end

    it "uses as_json when an object offers it" do
      serializer = Class.new do
        def as_json(*) = { "total" => "$10.00" }
      end

      expect(JSON.parse(described_class.dump(serializer.new))).to eq("total" => "$10.00")
    end

    # T12: the point is the key path, not merely that it raises.
    it "names the key path of a non-serializable value" do
      expect { described_class.dump({ invoice: { line_items: [{ amount: Object.new }] } }) }
        .to raise_error(ArgumentError, /data\.invoice\.line_items\[0\]\.amount/)
    end

    it "names the key path of a non-finite float" do
      expect { described_class.dump({ totals: { ratio: Float::INFINITY } }) }
        .to raise_error(ArgumentError, /data\.totals\.ratio is Infinity/)
    end

    it "rejects a hash key JSON cannot represent" do
      expect { described_class.dump({ [1, 2] => "x" }) }
        .to raise_error(ArgumentError, /JSON object keys must be/)
    end

    it "fails before any compilation happens" do
      with_templates("probe.typ" => "= Hi") do
        expect { Typstify.render(template: "probe", data: { bad: Object.new }) }
          .to raise_error(ArgumentError, /data\.bad/)
      end
    end
  end
end
