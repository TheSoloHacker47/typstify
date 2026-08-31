// Certificate — Typstify starter template.
//
// Landscape, centred, and deliberately restrained: a border, a name, a reason.
// Data mode; see templates/invoice for the fuller commentary.

#import "shared/branding.typ": *

#let data = json("data.json")

#set page(
  paper: "a4",
  flipped: true,
  margin: 16mm,
  background: {
    place(center + horizon, rect(
      width: 100% - 10mm,
      height: 100% - 10mm,
      stroke: 1.5pt + brand.accent,
      radius: 2pt,
    ))
    place(center + horizon, rect(
      width: 100% - 14mm,
      height: 100% - 14mm,
      stroke: 0.5pt + brand.rule,
    ))
  },
)
#set text(font: brand.font, size: 11pt, fill: brand.ink)

#align(center)[
  #v(14mm)
  #text(size: 9pt, fill: brand.muted, tracking: 2pt)[#upper(data.at("eyebrow", default: "Certificate"))]

  #v(6mm)
  #text(size: 30pt, weight: "semibold", fill: brand.accent)[#data.title]

  #v(8mm)
  #text(size: 10pt, fill: brand.muted)[#data.presented_to_label]

  #v(3mm)
  #text(size: 26pt, weight: "semibold")[#data.recipient]

  #v(3mm)
  #line(length: 70mm, stroke: 0.5pt + brand.rule)

  #v(6mm)
  #block(width: 60%)[
    #set par(justify: false, leading: 0.8em)
    #text(size: 11pt, fill: brand.muted)[#data.description]
  ]

  #v(14mm)

  #grid(
    columns: (1fr, 1fr),
    gutter: 30mm,
    ..data.signatories.map(person => [
      #line(length: 100%, stroke: 0.5pt + brand.ink)
      #v(2pt)
      #text(size: 10pt, weight: "semibold")[#person.name]
      #linebreak()
      #text(size: 8.5pt, fill: brand.muted)[#person.role]
    ]),
  )

  #v(8mm)
  #text(size: 8pt, fill: brand.muted)[
    #data.issued_on #h(6pt) · #h(6pt) #data.reference
  ]
]
