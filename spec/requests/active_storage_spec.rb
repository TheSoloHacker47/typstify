# frozen_string_literal: true

require "rails_helper"

# T10
RSpec.describe "Typstify.render_and_attach" do
  let(:owner) { DocumentOwner.create!(name: "Ada") }
  let(:data) { { number: "A-1", customer: "Ada", total: "$1.00", line_items: [] } }

  it "attaches a PDF blob" do
    Typstify.render_and_attach(owner.documents, template: "invoices/show",
                                                data: data, filename: "invoice-A-1.pdf")

    expect(owner.documents.count).to eq(1)
  end

  it "sets the filename and content type" do
    Typstify.render_and_attach(owner.documents, template: "invoices/show",
                                                data: data, filename: "invoice-A-1.pdf")
    blob = owner.documents.first.blob

    expect(blob.filename.to_s).to eq("invoice-A-1.pdf")
    expect(blob.content_type).to eq("application/pdf")
  end

  it "stores the actual PDF bytes" do
    Typstify.render_and_attach(owner.documents, template: "invoices/show",
                                                data: data, filename: "invoice-A-1.pdf")

    expect(owner.documents.first.blob.download).to start_with("%PDF-")
  end

  it "does not attach anything when the data is unserializable" do
    expect do
      Typstify.render_and_attach(owner.documents, template: "invoices/show",
                                                  data: { bad: Object.new }, filename: "x.pdf")
    end.to raise_error(ArgumentError)

    expect(owner.documents.count).to eq(0)
  end
end
