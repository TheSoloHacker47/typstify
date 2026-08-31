# frozen_string_literal: true

Rails.application.routes.draw do
  get "/invoices/:id", to: "invoices#show", as: :invoice
  get "/invoices/:id/inline", to: "invoices#inline"
  get "/invoices/:id/named", to: "invoices#named"
  get "/invoices/:id/erb", to: "invoices#erb"
  get "/invoices/:id/raw_erb", to: "invoices#raw_erb"
  get "/missing", to: "invoices#missing"
  get "/broken", to: "invoices#broken"
end
