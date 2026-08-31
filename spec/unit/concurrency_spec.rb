# frozen_string_literal: true

require "spec_helper"

# T7. Every render gets its own workspace, so twenty at once must produce
# twenty correct documents rather than twenty copies of whichever data.json
# was written last.
RSpec.describe "concurrent rendering" do
  it "keeps twenty simultaneous renders isolated from each other" do
    template = { "probe.typ" => %(#let data = json("data.json")\nMarker: #data.marker) }

    with_templates(template) do
      results = 20.times.map do |i|
        Thread.new { [i, Typstify.render(template: "probe", data: { marker: "marker-#{i}" })] }
      end.map(&:value)

      expect(results.size).to eq(20)
      results.each do |(i, pdf)|
        expect(pdf).to start_with("%PDF-")
        expect(pdf_text(pdf)).to include("Marker: marker-#{i}")
      end
    end
  end
end
