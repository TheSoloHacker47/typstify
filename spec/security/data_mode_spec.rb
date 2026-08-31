# frozen_string_literal: true

require "spec_helper"

# Everything a determined caller might try to smuggle through a customer name.
HOSTILE_PAYLOADS = [
  '#read("secret.txt")',
  '#eval("1 + 1")',
  "#import \"shared/branding.typ\": *",
  "*bold*",
  "_emphasis_",
  "$e^(i pi)$",
  "#pagebreak()",
  '"; #read("/etc/passwd"); "',
  "\\#read(\"secret.txt\")"
].freeze

# T2 — the central claim of this gem.
#
# In data mode a template never sees your Ruby strings as source. Values go out
# as JSON and come back through Typst's `json()`, which yields *data*. There is
# no parse step in which a `#` could become a function call, so hostile input
# has nothing to escape from. These specs assert that property directly rather
# than testing an escaping routine, because in data mode there isn't one.
RSpec.describe "data mode is injection-safe" do
  let(:template) do
    {
      "probe.typ" => <<~TYP,
        #let data = json("data.json")
        Name: #data.name
      TYP
      "secret.txt" => "SUPERSECRETVALUE"
    }
  end

  HOSTILE_PAYLOADS.each do |payload|
    it "renders #{payload.inspect} as literal text" do
      with_templates(template) do
        text = pdf_text(Typstify.render(template: "probe", data: { name: payload }))

        expect(text).to include(payload)
      end
    end
  end

  it "does not execute a #read() smuggled through data" do
    with_templates(template) do
      text = pdf_text(Typstify.render(template: "probe", data: { name: '#read("secret.txt")' }))

      expect(text).not_to include("SUPERSECRETVALUE")
    end
  end

  # The file is not merely unread — it was never copied into the workspace, so
  # there is nothing for a template to read even if it tried.
  it "never copies unrelated files from template_root into the workspace" do
    with_templates(template.merge("probe.typ" => %(#let secret = read("secret.txt")\n#secret))) do
      expect { Typstify.render(template: "probe") }
        .to raise_error(Typstify::CompileError, /file not found|failed to load/i)
    end
  end

  it "cannot reach outside the workspace root at all" do
    with_templates("probe.typ" => %(#let host = read("../../../../etc/hosts")\n#host)) do
      expect { Typstify.render(template: "probe") }.to raise_error(Typstify::CompileError)
    end
  end

  it "keeps hostile content out of the document structure" do
    with_templates(template) do
      pdf = Typstify.render(template: "probe", data: { name: "#pagebreak()" })

      # An executed #pagebreak() would produce a second page. It prints instead.
      expect(pdf_page_count(pdf)).to eq(1)
    end
  end
end
