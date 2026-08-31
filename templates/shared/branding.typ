// Shared branding for every Typstify document.
//
// Change it once here and every invoice, receipt, report and certificate
// follows. Nothing in this file reads data.json — it is pure presentation, so
// it can be imported by any template.

#let brand = (
  name: "Your Company",
  tagline: "",
  accent: rgb("#1f5eff"),
  ink: rgb("#111827"),
  muted: rgb("#6b7280"),
  rule: rgb("#e5e7eb"),
  font: "Inter",
)

// Base page setup. Wrap a document with:  #show: brand-page
#let brand-page(body) = {
  set page(
    paper: "a4",
    margin: (x: 18mm, y: 20mm),
    footer: context [
      #set text(size: 8pt, fill: brand.muted)
      #line(length: 100%, stroke: 0.5pt + brand.rule)
      #v(2pt)
      #grid(
        columns: (1fr, auto),
        align: (left, right),
        [#brand.name],
        [Page #counter(page).display() of #context counter(page).final().first()],
      )
    ],
  )
  set text(font: brand.font, size: 10pt, fill: brand.ink)
  set par(justify: false, leading: 0.65em)
  show heading: set text(weight: "semibold")
  body
}

// Document header: a title on the left, the company block on the right.
#let brand-header(title: "", subtitle: none, meta: ()) = {
  grid(
    columns: (1fr, auto),
    align: (left + bottom, right + bottom),
    [
      #text(size: 22pt, weight: "semibold", fill: brand.accent)[#title]
      #if subtitle != none [
        #linebreak()
        #text(size: 10pt, fill: brand.muted)[#subtitle]
      ]
    ],
    [
      #text(size: 11pt, weight: "semibold")[#brand.name]
      #if brand.tagline != "" [
        #linebreak()
        #text(size: 9pt, fill: brand.muted)[#brand.tagline]
      ]
    ],
  )
  v(4pt)
  line(length: 100%, stroke: 1pt + brand.accent)
  if meta.len() > 0 {
    v(6pt)
    grid(
      columns: meta.len(),
      gutter: 16pt,
      ..meta.map(pair => [
        #text(size: 8pt, fill: brand.muted, upper(pair.at(0)))
        #linebreak()
        #text(size: 10pt)[#pair.at(1)]
      ]),
    )
  }
  v(10pt)
}

// A labelled block of lines, e.g. an address.
#let brand-address(label: "", lines: ()) = [
  #text(size: 8pt, fill: brand.muted)[#upper(label)]
  #linebreak()
  #for line in lines [
    #line
    #linebreak()
  ]
]

// The standard table styling used by the invoice and receipt templates.
#let brand-table(columns: (), header: (), rows: (), aligns: none) = {
  set text(size: 9.5pt)
  table(
    columns: columns,
    align: if aligns == none { left } else { (col, _) => aligns.at(col) },
    stroke: (x, y) => (
      bottom: if y == 0 { 1pt + brand.rule } else { 0.5pt + brand.rule },
    ),
    inset: (x: 6pt, y: 7pt),
    table.header(..header.map(cell => text(
      size: 8pt,
      weight: "semibold",
      fill: brand.muted,
    )[#upper(cell)])),
    ..rows.flatten(),
  )
}

// Right-aligned totals block.
#let brand-totals(rows: (), emphasis: none) = align(right)[
  #block(width: 62mm)[
    #for row in rows [
      #grid(
        columns: (1fr, auto),
        gutter: 12pt,
        align: (left, right),
        text(fill: brand.muted)[#row.at(0)],
        [#row.at(1)],
      )
      #v(2pt)
    ]
    #if emphasis != none [
      #line(length: 100%, stroke: 0.5pt + brand.rule)
      #v(4pt)
      #grid(
        columns: (1fr, auto),
        gutter: 12pt,
        align: (left, right),
        text(weight: "semibold")[#emphasis.at(0)],
        text(weight: "semibold", size: 12pt, fill: brand.accent)[#emphasis.at(1)],
      )
    ]
  ]
]

#let brand-note(body) = block(
  width: 100%,
  fill: rgb("#f9fafb"),
  stroke: 0.5pt + brand.rule,
  radius: 3pt,
  inset: 10pt,
  text(size: 9pt, fill: brand.muted)[#body],
)
