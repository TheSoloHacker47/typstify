// Invoice — Typstify starter template.
//
// Data mode: every dynamic value arrives as JSON. Nothing here interpolates a
// Ruby string into source, so a customer named `#read("/etc/passwd")` renders
// as those characters and nothing else.
//
// Preview it without booting Rails:
//   rake typstify:preview[invoices/show]

#import "shared/branding.typ": *

#let data = json("data.json")

#show: brand-page

#brand-header(
  title: "Invoice " + data.number,
  subtitle: data.at("subtitle", default: none),
  meta: (
    ("Issued", data.issued_on),
    ("Due", data.due_on),
    ("Amount due", data.total),
  ),
)

#grid(
  columns: (1fr, 1fr),
  gutter: 16pt,
  brand-address(label: "Billed to", lines: data.bill_to),
  brand-address(label: "From", lines: data.bill_from),
)

#v(14pt)

#brand-table(
  columns: (1fr, auto, auto, auto),
  aligns: (left, right, right, right),
  header: ("Description", "Qty", "Unit", "Amount"),
  rows: data.line_items.map(item => (
    [#item.name],
    [#item.qty],
    [#item.unit_price],
    [#item.amount],
  )),
)

#v(12pt)

#brand-totals(
  rows: data.at("summary", default: ()).map(row => (row.label, row.value)),
  emphasis: ("Total due", data.total),
)

#if data.at("notes", default: none) != none [
  #v(16pt)
  #brand-note[#data.notes]
]
