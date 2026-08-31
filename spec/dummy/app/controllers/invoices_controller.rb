# frozen_string_literal: true

class InvoicesController < ActionController::Base
  def show
    render pdf: "invoices/show", data: invoice_data
  end

  def inline
    render pdf: "invoices/show", data: invoice_data, disposition: :inline
  end

  def named
    render pdf: "invoices/show", data: invoice_data, filename: "invoice-#{params[:id]}.pdf"
  end

  def erb
    @customer = params[:customer] || "Ada Okonkwo"
    render pdf: "invoices/escaped", data: { number: params[:id] }
  end

  def raw_erb
    @customer = params[:customer] || "Ada Okonkwo"
    render pdf: "invoices/unescaped", data: { number: params[:id] }
  end

  def missing
    render pdf: "invoices/nope", data: {}
  end

  def broken
    render pdf: "invoices/broken", data: {}
  end

  private

  def invoice_data
    {
      number: params[:id],
      customer: params[:customer] || "Northwind Trading Ltd.",
      total: "$4,860.00",
      line_items: [
        { name: "Platform subscription", qty: 1, amount: "$2,400.00" },
        { name: "Additional seats", qty: 12, amount: "$1,140.00" }
      ]
    }
  end
end
