# frozen_string_literal: true

require "spec_helper"

# T3 — ERB mode, where the safety property above does not hold for free.
#
# `.typ.erb` splices Ruby strings into Typst *source*. That is code, and an
# unescaped value is code injection. The gem's answer is `typ()`, and the
# second half of this file deliberately documents what happens without it —
# not because the raw behaviour is acceptable, but because a suite that only
# tests the safe path hides the shape of the risk from the next reader.
RSpec.describe "ERB mode escaping" do
  let(:hostile) { '#read("secret.txt")' }
  let(:files) do
    {
      "escaped.typ.erb" => "Name: <%= typ(data[:name]) %>",
      "unescaped.typ.erb" => "Name: <%= data[:name] %>",
      "secret.txt" => "SUPERSECRETVALUE"
    }
  end

  describe "with typ()" do
    it "renders the hostile string literally" do
      with_templates(files) do
        text = pdf_text(Typstify.render(template: "escaped", data: { name: hostile }))

        expect(text).to include(hostile)
      end
    end

    it "renders markup literally too" do
      with_templates(files) do
        text = pdf_text(Typstify.render(template: "escaped", data: { name: "*not bold* [not a block]" }))

        expect(text).to include("*not bold* [not a block]")
      end
    end

    it "exposes controller instance variables alongside typ()" do
      with_templates("greeting.typ.erb" => "Hello <%= typ(@customer) %>") do
        text = pdf_text(Typstify.render(template: "greeting", assigns: { customer: "Ada *Okonkwo*" }))

        expect(text).to include("Ada *Okonkwo*")
      end
    end
  end

  # DOCUMENTING, NOT ENDORSING. Each of these asserts the unsafe outcome so a
  # regression that changes it is visible, and so the risk is legible to anyone
  # reading the suite. This is why the README says: use data mode.
  describe "without typ() — documented unsafe behaviour" do
    it "lets user input become Typst code" do
      with_templates(files) do
        # The compile fails because the smuggled call is *evaluated*: the file
        # is not in the workspace. Had it been, it would have been read.
        expect { Typstify.render(template: "unescaped", data: { name: hostile }) }
          .to raise_error(Typstify::CompileError)
      end
    end

    it "lets user input change document structure" do
      with_templates(files) do
        pdf = Typstify.render(template: "unescaped", data: { name: "#pagebreak()" })

        # Compare with the data-mode spec, where the same payload stays on one page.
        expect(pdf_page_count(pdf)).to be > 1
      end
    end

    it "lets user input apply formatting" do
      with_templates(files) do
        text = pdf_text(Typstify.render(template: "unescaped", data: { name: "*bold*" }))

        # The asterisks are gone: they were parsed as markup, not printed.
        expect(text).to include("bold")
        expect(text).not_to include("*bold*")
      end
    end
  end
end
