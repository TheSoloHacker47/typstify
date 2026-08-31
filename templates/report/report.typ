// Report — Typstify starter template.
//
// A multi-page document: cover block, headline metrics, a data table and
// free-form sections. This is the one that shows why Typst beats a coordinate
// DSL — pagination, running headers and a table of contents come for free.
//
// Data mode; see templates/invoice for the fuller commentary.

#import "shared/branding.typ": *

#let data = json("data.json")

#show: brand-page

#brand-header(
  title: data.title,
  subtitle: data.at("subtitle", default: none),
  meta: (
    ("Period", data.period),
    ("Prepared for", data.prepared_for),
    ("Generated", data.generated_on),
  ),
)

// Headline metrics.
#grid(
  columns: data.metrics.len(),
  gutter: 10pt,
  ..data.metrics.map(metric => block(
    width: 100%,
    fill: rgb("#f9fafb"),
    stroke: 0.5pt + brand.rule,
    radius: 3pt,
    inset: 10pt,
  )[
    #text(size: 8pt, fill: brand.muted)[#upper(metric.label)]
    #linebreak()
    #text(size: 18pt, weight: "semibold")[#metric.value]
    #linebreak()
    // Always a third line, present or not, so the cards line up. `height: 100%`
    // is the obvious alternative and the wrong one: inside a grid it resolves
    // against the page, not the row, and pushes the whole report onto page two.
    #if metric.at("change", default: none) == none [
      #text(size: 9pt)[ ]
    ] else [
      #text(size: 9pt, fill: if metric.at("positive", default: true) {
        rgb("#047857")
      } else {
        rgb("#b91c1c")
      })[#metric.change]
    ]
  ]),
)

#v(16pt)

#heading(level: 1, outlined: false)[#data.table.heading]
#v(2pt)

#brand-table(
  columns: (1fr,) + data.table.columns.slice(1).map(_ => auto),
  aligns: (left,) + data.table.columns.slice(1).map(_ => right),
  header: data.table.columns,
  rows: data.table.rows.map(row => row.map(cell => [#cell])),
)

// A simple bar chart, drawn with rectangles. No plotting library, no browser.
#if data.at("bars", default: none) != none [
  #v(16pt)
  #heading(level: 1, outlined: false)[#data.bars.heading]
  #v(6pt)
  #let peak = calc.max(..data.bars.series.map(bar => bar.value))
  #for bar in data.bars.series [
    #grid(
      columns: (28mm, 1fr, 18mm),
      gutter: 8pt,
      align: (left + horizon, left + horizon, right + horizon),
      text(size: 9pt)[#bar.label],
      box(width: 100%)[
        #rect(
          width: 100% * (bar.value / peak),
          height: 8pt,
          radius: 2pt,
          fill: brand.accent,
          stroke: none,
        )
      ],
      text(size: 9pt, fill: brand.muted)[#bar.display],
    )
    #v(4pt)
  ]
]

#for section in data.sections [
  #v(14pt)
  #heading(level: 1, outlined: false)[#section.heading]
  #v(2pt)
  #set par(justify: true)
  #for paragraph in section.body [
    #paragraph
    #parbreak()
  ]
]
