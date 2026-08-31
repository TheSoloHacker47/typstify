#import "shared/branding.typ": brand-header, brand-footer

#let data = json("data.json")

#brand-header(title: "Invoice " + data.number)

Customer: #data.customer

#table(
  columns: (1fr, auto, auto),
  [*Item*], [*Qty*], [*Amount*],
  ..data.line_items.map(item => ([#item.name], [#item.qty], [#item.amount])).flatten()
)

#align(right)[*Total: #data.total*]

#brand-footer()
