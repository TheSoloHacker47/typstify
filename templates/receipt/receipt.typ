// Receipt — Typstify starter template.
//
// A payment confirmation: narrower page, no billing terms, a paid stamp.
// Data mode; see templates/invoice for the fuller commentary.

#import "shared/branding.typ": *

#let data = json("data.json")

#show: brand-page

#set page(paper: "a5", margin: (x: 14mm, y: 16mm))

#brand-header(
  title: "Receipt",
  subtitle: data.at("subtitle", default: none),
  meta: (
    ("Receipt no.", data.number),
    ("Paid on", data.paid_on),
  ),
)

#block(
  width: 100%,
  fill: rgb("#ecfdf5"),
  stroke: 0.5pt + rgb("#a7f3d0"),
  radius: 3pt,
  inset: 10pt,
)[
  #grid(
    columns: (1fr, auto),
    align: (left + horizon, right + horizon),
    [
      #text(size: 8pt, fill: rgb("#047857"))[#upper("Paid in full")]
      #linebreak()
      #text(size: 9pt, fill: brand.muted)[#data.method]
    ],
    text(size: 16pt, weight: "semibold", fill: rgb("#047857"))[#data.total],
  )
]

#v(12pt)

#brand-address(label: "Received from", lines: data.received_from)

#v(12pt)

#brand-table(
  columns: (1fr, auto, auto),
  aligns: (left, right, right),
  header: ("Description", "Qty", "Amount"),
  rows: data.line_items.map(item => (
    [#item.name],
    [#item.qty],
    [#item.amount],
  )),
)

#v(10pt)

#brand-totals(
  rows: data.at("summary", default: ()).map(row => (row.label, row.value)),
  emphasis: ("Total paid", data.total),
)

#if data.at("notes", default: none) != none [
  #v(12pt)
  #brand-note[#data.notes]
]
