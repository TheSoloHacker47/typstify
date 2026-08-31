# Migrating from wicked_pdf

There is no HTML→Typst converter, and there will not be one. You rewrite each PDF view.

That sounds worse than it is. Most applications have two to five PDF views, and each is a
short sitting rather than a project — the layout ideas transfer directly, and you end up with
fewer lines than you started with. What follows is a real invoice, converted, with nothing
trimmed to flatter the result.

## The before: a wicked_pdf invoice

82 lines. Styling is inlined into the view, because that is what wkhtmltopdf's stylesheet
handling pushes you towards.

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <style>
      @page { size: A4; margin: 18mm; }
      body { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 10pt; color: #111827; }
      .header { display: table; width: 100%; border-bottom: 2px solid #1f5eff; padding-bottom: 6px; }
      .header .title { display: table-cell; font-size: 22pt; font-weight: 600; color: #1f5eff; }
      .header .company { display: table-cell; text-align: right; vertical-align: bottom; font-weight: 600; }
      .meta { margin-top: 10px; width: 100%; }
      .meta td { padding-right: 24px; }
      .meta .label { font-size: 8pt; color: #6b7280; text-transform: uppercase; }
      table.items { width: 100%; border-collapse: collapse; margin-top: 18px; }
      table.items th { font-size: 8pt; color: #6b7280; text-transform: uppercase;
                       text-align: right; border-bottom: 1px solid #e5e7eb; padding: 7px 6px; }
      table.items th:first-child { text-align: left; }
      table.items td { text-align: right; border-bottom: 1px solid #e5e7eb; padding: 7px 6px; }
      table.items td:first-child { text-align: left; }
      .totals { width: 62mm; margin-left: auto; margin-top: 12px; }
      .totals td { padding: 2px 0; }
      .totals td.value { text-align: right; }
      .totals tr.grand td { border-top: 1px solid #e5e7eb; padding-top: 6px;
                            font-weight: 600; font-size: 12pt; color: #1f5eff; }
      .note { margin-top: 16px; background: #f9fafb; border: 1px solid #e5e7eb;
              border-radius: 3px; padding: 10px; font-size: 9pt; color: #6b7280; }
      .footer { position: fixed; bottom: 0; width: 100%; font-size: 8pt; color: #6b7280;
                border-top: 1px solid #e5e7eb; padding-top: 4px; }
    </style>
  </head>
  <body>
    <div class="header">
      <div class="title">Invoice <%= @invoice.number %></div>
      <div class="company"><%= @company.name %></div>
    </div>

    <table class="meta">
      <tr>
        <td class="label">Issued</td>
        <td class="label">Due</td>
        <td class="label">Amount due</td>
      </tr>
      <tr>
        <td><%= l @invoice.issued_on, format: :long %></td>
        <td><%= l @invoice.due_on, format: :long %></td>
        <td><%= humanized_money_with_symbol @invoice.total %></td>
      </tr>
    </table>

    <table class="items">
      <thead>
        <tr><th>Description</th><th>Qty</th><th>Unit</th><th>Amount</th></tr>
      </thead>
      <tbody>
        <% @invoice.line_items.each do |item| %>
          <tr>
            <td><%= item.name %></td>
            <td><%= item.qty %></td>
            <td><%= humanized_money_with_symbol item.unit_price %></td>
            <td><%= humanized_money_with_symbol item.amount %></td>
          </tr>
        <% end %>
      </tbody>
    </table>

    <table class="totals">
      <% @invoice.summary_rows.each do |row| %>
        <tr><td><%= row.label %></td><td class="value"><%= row.value %></td></tr>
      <% end %>
      <tr class="grand">
        <td>Total due</td>
        <td class="value"><%= humanized_money_with_symbol @invoice.total %></td>
      </tr>
    </table>

    <% if @invoice.notes.present? %>
      <div class="note"><%= @invoice.notes %></div>
    <% end %>

    <div class="footer"><%= @company.name %></div>
  </body>
</html>
```

Plus the controller:

```ruby
def show
  @invoice = Invoice.find(params[:id])
  @company = Current.company
  render pdf: "invoice",
         template: "invoices/show",
         layout: false,
         page_size: "A4",
         margin: { top: 18, bottom: 18, left: 18, right: 18 },
         footer: { content: render_to_string("invoices/_footer", layout: false) },
         disable_smart_shrinking: true
end
```

Note what is happening in those options: page geometry, and a *second render pass* for the
footer, because wkhtmltopdf cannot reuse the page's own DOM for running elements.

## The after: the same invoice in Typst

55 lines, and this version is self-contained — no shared partial, so the comparison is
like-for-like.

```typ
#let data = json("data.json")
#let accent = rgb("#1f5eff")
#let muted = rgb("#6b7280")
#let rule = rgb("#e5e7eb")

#set page(paper: "a4", margin: 18mm, footer: context [
  #set text(size: 8pt, fill: muted)
  #line(length: 100%, stroke: 0.5pt + rule)
  #data.company
])
#set text(font: "Inter", size: 10pt, fill: rgb("#111827"))

#grid(
  columns: (1fr, auto),
  align: (left + bottom, right + bottom),
  text(size: 22pt, weight: "semibold", fill: accent)[Invoice #data.number],
  text(weight: "semibold")[#data.company],
)
#line(length: 100%, stroke: 2pt + accent)

#v(10pt)
#grid(
  columns: 3,
  gutter: 24pt,
  ..(("Issued", data.issued_on), ("Due", data.due_on), ("Amount due", data.total)).map(pair => [
    #text(size: 8pt, fill: muted)[#upper(pair.at(0))] \
    #pair.at(1)
  ]),
)

#v(18pt)
#table(
  columns: (1fr, auto, auto, auto),
  align: (col, _) => if col == 0 { left } else { right },
  stroke: (x, y) => (bottom: 0.5pt + rule),
  inset: (x: 6pt, y: 7pt),
  table.header(..("Description", "Qty", "Unit", "Amount").map(h =>
    text(size: 8pt, fill: muted)[#upper(h)])),
  ..data.line_items.map(i => ([#i.name], [#i.qty], [#i.unit_price], [#i.amount])).flatten(),
)

#v(12pt)
#align(right, block(width: 62mm)[
  #for row in data.summary [
    #grid(columns: (1fr, auto), gutter: 12pt, align: (left, right), row.label, row.value)
  ]
  #line(length: 100%, stroke: 0.5pt + rule)
  #grid(columns: (1fr, auto), gutter: 12pt, align: (left, right),
    text(weight: "semibold")[Total due],
    text(weight: "semibold", size: 12pt, fill: accent)[#data.total])
])

#v(16pt)
#block(width: 100%, fill: rgb("#f9fafb"), stroke: 0.5pt + rule, radius: 3pt, inset: 10pt,
  text(size: 9pt, fill: muted)[#data.notes])
```

And the controller:

```ruby
def show
  invoice = Invoice.find(params[:id])
  render pdf: "invoices/show",
         data: InvoiceSerializer.new(invoice).as_json,
         filename: "invoice-#{invoice.number}.pdf"
end
```

Page geometry moved into the template, where it belongs. The footer is `set page(footer: …)` —
declared once, rendered on every page, no second pass.

## What changed, concept by concept

| wicked_pdf | typstify |
|---|---|
| `@page { size: A4; margin: 18mm }` | `set page(paper: "a4", margin: 18mm)` |
| `position: fixed` footer + a second `render_to_string` | `set page(footer: …)` |
| `<table>` + `border-collapse` + `td:first-child` alignment | `table(columns:, align:, stroke:, inset:)` |
| `<% @invoice.line_items.each do |item| %>` | `data.line_items.map(i => …)` |
| `display: table` hacks for a two-column header row | `grid(columns: (1fr, auto))` |
| CSS classes shared via a stylesheet | a `.typ` module you `#import` |
| instance variables interpolated into HTML | `data.json`, read as data |
| `humanized_money_with_symbol` in the view | format in Ruby, pass the string |

That last row is the one that changes how you think. Typst templates do not call your helpers.
Formatting — currency, dates, pluralisation, translation — happens in Ruby, in a serializer,
and the template receives finished strings. This is a constraint, and it is the constraint that
makes the whole thing injection-safe: if the template cannot call code, user data cannot make
it call code either.

## A conversion checklist

1. **Write the serializer first.** Everything the view interpolates becomes a key. Format it in
   Ruby: `invoice.total.format`, `l(invoice.issued_on, format: :long)`, `t(".paid")`.
2. **Port the page frame**: paper, margins, header, footer. One `set page(…)` call.
3. **Port the type**: `set text(font:, size:, fill:)`. Vendor the font — see
   [fonts-and-docker.md](fonts-and-docker.md).
4. **Port the tables.** Typst's `table` takes columns, alignment and stroke as arguments
   rather than as selectors; a `stroke: (x, y) => …` closure replaces `tr:last-child` rules.
5. **Move shared styling into `app/views/shared/branding.typ`** once you have converted the
   second document. The starter pack's `branding.typ` is a working example.
6. **Delete the wicked_pdf render options** — page size, margins, footer passes, shrinking
   flags. They have no equivalent because they have no need.

## Things that will not port

- **JavaScript-rendered content.** wkhtmltopdf ran a browser; Typst does not. Compute it in
  Ruby and pass it in.
- **Charts drawn by a JS library.** Typst draws natively (the starter `report` template has a
  bar chart in nine lines) or you can pass an SVG through and `image()` it.
- **`render_to_string` of an existing HTML partial.** Templates are Typst, not HTML.
- **Helpers.** By design; see above.

## Running both during the transition

Nothing conflicts. `render pdf:` is a renderer key, and wicked_pdf registers its own; you can
convert one view at a time and delete the wicked_pdf dependency at the end. If you want both
registered simultaneously, keep wicked_pdf's `render pdf:` and call `Typstify.render` directly
from the actions you have converted:

```ruby
def show
  send_data Typstify.render(template: "invoices/show", data: payload),
            type: "application/pdf", filename: "invoice.pdf", disposition: :inline
end
```

Then remove the gem, and the renderer key is yours.
