# frozen_string_literal: true

require "rails_helper"

# T12, in the environment where it is easy to get wrong.
#
# ActiveSupport adds `as_json` to Object itself, so under Rails *everything*
# answers `respond_to?(:as_json)` and a naive serializer would quietly turn a
# Proc or a half-built value object into `{}` — a blank invoice, no error.
RSpec.describe "data validation under ActiveSupport" do
  it "still rejects a plain object, despite Object#as_json existing" do
    expect(Object.new).to respond_to(:as_json)

    expect { Typstify::Data.dump({ invoice: { customer: Object.new } }) }
      .to raise_error(ArgumentError, /data\.invoice\.customer is a Object/)
  end

  it "rejects a Proc" do
    expect { Typstify::Data.dump({ callback: -> { 1 } }) }
      .to raise_error(ArgumentError, /data\.callback is a Proc/)
  end

  it "accepts an ActiveRecord model, which defines its own as_json" do
    owner = DocumentOwner.create!(name: "Ada")

    expect(JSON.parse(Typstify::Data.dump({ owner: owner })).dig("owner", "name")).to eq("Ada")
  end

  it "accepts an object that defines as_json deliberately" do
    serializer = Class.new do
      def as_json(*) = { "number" => "A-1" }
    end

    expect(JSON.parse(Typstify::Data.dump({ invoice: serializer.new }))).to eq("invoice" => { "number" => "A-1" })
  end

  it "serialises Time and Date without configuration" do
    json = JSON.parse(Typstify::Data.dump({ at: Time.utc(2026, 3, 12, 9, 0, 0), on: Date.new(2026, 3, 12) }))

    expect(json["at"]).to start_with("2026-03-12")
    expect(json["on"]).to eq("2026-03-12")
  end

  it "rejects a BigDecimal-shaped infinity rather than writing Infinity into JSON" do
    expect { Typstify::Data.dump({ ratio: Float::INFINITY }) }
      .to raise_error(ArgumentError, /Infinity/)
  end
end
