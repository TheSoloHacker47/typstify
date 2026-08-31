# frozen_string_literal: true

require "rails_helper"

# T1 / T11 — the renderer, exercised through a real Rails stack.
RSpec.describe "render pdf:", type: :request do
  it "responds with a PDF" do
    get "/invoices/A-1"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.body).to start_with("%PDF-")
  end

  it "defaults to an attachment named after the template" do
    get "/invoices/A-1"

    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("show.pdf")
  end

  it "honours filename:" do
    get "/invoices/A-1/named"

    expect(response.headers["Content-Disposition"]).to include("invoice-A-1.pdf")
  end

  it "honours disposition: :inline" do
    get "/invoices/A-1/inline"

    expect(response.headers["Content-Disposition"]).to include("inline")
  end

  it "passes data through to the template" do
    get "/invoices/A-1", params: { customer: "Northwind Trading Ltd." }

    expect(pdf_text(response.body)).to include("Invoice A-1").and include("Northwind Trading Ltd.")
  end

  it "renders values from the shared branding partial" do
    get "/invoices/A-1"

    expect(pdf_text(response.body)).to include("Dummy Co.")
  end

  # T11
  it "raises MissingTemplate listing both paths it tried" do
    expect { get "/missing" }
      .to raise_error(Typstify::MissingTemplate, %r{invoices/nope\.typ.*invoices/nope\.typ\.erb}m)
  end

  # T5, through the stack: the standard Rails error page renders this message.
  it "raises CompileError carrying the compiler's message" do
    expect { get "/broken" }.to raise_error(Typstify::CompileError, /expected expression/)
  end

  describe "ERB templates" do
    it "escapes with typ()" do
      get "/invoices/A-1/erb", params: { customer: "Ada *Okonkwo*" }

      expect(pdf_text(response.body)).to include("Ada *Okonkwo*")
    end

    it "reaches controller instance variables" do
      get "/invoices/A-1/erb", params: { customer: "Ada Okonkwo" }

      expect(pdf_text(response.body)).to include("Customer: Ada Okonkwo")
    end
  end
end
