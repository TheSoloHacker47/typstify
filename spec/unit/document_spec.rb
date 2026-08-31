# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typstify::Document do
  it "returns PDF bytes" do
    with_templates("probe.typ" => "= Hello") do
      pdf = Typstify.render(template: "probe")

      expect(pdf).to start_with("%PDF-")
      expect(pdf.encoding).to eq(Encoding::ASCII_8BIT)
    end
  end

  it "reads data.json from the template" do
    with_templates("probe.typ" => %(#let data = json("data.json")\nNumber: #data.number)) do
      expect(pdf_text(Typstify.render(template: "probe", data: { number: "A-1" })))
        .to include("Number: A-1")
    end
  end

  it "renders typographic characters when the environment has no locale" do
    with_templates("probe.typ" => "Em dash — and a café") do
      expect(pdf_text(Typstify.render(template: "probe"))).to include("Em dash — and a café")
    end
  end

  # T5
  describe "a template that will not compile" do
    let(:broken) { { "invoices/show.typ" => "= Heading\n\n#let x =\n" } }

    it "raises CompileError" do
      with_templates(broken) do
        expect { Typstify.render(template: "invoices/show") }.to raise_error(Typstify::CompileError)
      end
    end

    it "carries the compiler's own message and the line" do
      with_templates(broken) do
        Typstify.render(template: "invoices/show")
      rescue Typstify::CompileError => e
        expect(e.typst_message).to include("expected expression")
        expect(e.line).to eq(3)
      end
    end

    # A random tmpdir path in the error is noise; developers wrote a view.
    it "names the developer's template rather than the workspace" do
      with_templates(broken) do
        Typstify.render(template: "invoices/show")
      rescue Typstify::CompileError => e
        expect(e.message).to include("invoices/show.typ:3")
        expect(e.message).not_to include("typstify-")
      end
    end
  end

  describe "pdf_standard" do
    it "emits PDF/UA-1 when asked" do
      with_templates("probe.typ" => %(#set document(title: "Probe")\n= Hello)) do
        Typstify.config.pdf_standard = :ua_1

        expect(Typstify.render(template: "probe")).to start_with("%PDF-")
      end
    end
  end
end
