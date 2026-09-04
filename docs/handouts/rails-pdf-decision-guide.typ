#let data = json("data.json")

#let ink    = rgb("#111827")
#let muted  = rgb("#6b7280")
#let rule   = rgb("#e5e7eb")
#let accent = rgb("#1f5eff")
#let good   = rgb("#047857")
#let warn   = rgb("#b45309")
#let bad    = rgb("#b91c1c")

#let tone(flag) = if flag == "good" { good } else if flag == "ok" { ink } else if flag == "warn" { warn } else { bad }

#set document(title: data.title, author: "Nikhil Nelson", date: none)
#set page(
  paper: "a4",
  margin: (x: 14mm, y: 11mm),
  footer: context [
    #set text(size: 7.5pt, fill: muted)
    #line(length: 100%, stroke: 0.5pt + rule)
    #v(2pt)
    #grid(columns: (1fr, auto), align: (left, right),
      data.footer_left, data.footer_right)
  ],
)
#set text(font: "Inter", size: 9.1pt, fill: ink)
#set par(leading: 0.62em)

// ---------- header ----------
#text(size: 19pt, weight: "semibold", fill: accent)[#data.title]
#v(-4pt)
#text(size: 9.5pt, fill: muted)[#data.subtitle]
#v(3pt)
#line(length: 100%, stroke: 1.5pt + accent)
#v(8pt)

// ---------- matrix ----------
#let head(s) = text(size: 7.5pt, fill: muted, weight: "semibold")[#upper(s)]

#table(
  columns: (auto, auto, auto, auto, auto, 1fr),
  align: (left, left, left, left, left, left),
  stroke: (x, y) => (bottom: 0.5pt + rule),
  inset: (x: 6pt, y: 6.5pt),
  table.header(
    head("Library"), head("Engine"), head("Per doc"),
    head("Image cost"), head("Accessible"), head("Maintained"),
  ),
  ..data.rows.map(r => (
    text(weight: "semibold", fill: tone(r.flag))[#r.name],
    [#r.engine],
    [#r.speed],
    [#r.image],
    text(fill: tone(r.access_tone), weight: "medium")[#r.access],
    text(fill: tone(r.maint_tone), weight: "medium")[#r.maintained],
  )).flatten(),
)

#v(4pt)
#text(size: 7.5pt, fill: muted)[
  Timings measured on an M-series Mac compiling the same styled A4 invoice 40 times.
  "Accessible" means whether the pipeline can emit a tagged PDF a screen reader can navigate.
]

#v(10pt)

// ---------- picks ----------
#grid(
  columns: (1fr, 1fr),
  column-gutter: 10pt,
  row-gutter: 8pt,
  ..data.picks.map(p => block(
    width: 100%,
    fill: rgb("#f9fafb"),
    stroke: 0.5pt + rule,
    radius: 3pt,
    inset: 9pt,
  )[
    #text(weight: "semibold", size: 9.5pt)[#p.name]
    #v(2pt)
    #text(size: 8.4pt, fill: muted)[#p.body]
  ]),
)

#v(10pt)

// ---------- migration ----------
#block(width: 100%, fill: rgb("#eef3ff"), stroke: 0.5pt + rgb("#c7d7ff"), radius: 3pt, inset: 10pt)[
  #text(weight: "semibold", size: 10pt)[#data.migration.title]
  #v(4pt)
  #for (i, st) in data.migration.steps.enumerate() [
    #grid(columns: (14pt, 1fr), gutter: 4pt,
      text(size: 8.4pt, fill: accent, weight: "semibold")[#(i + 1).],
      text(size: 8.4pt, fill: muted)[#st])
    #v(2pt)
  ]
  #text(size: 8.6pt, style: "italic", fill: muted)[#data.migration.note]
]

#v(10pt)

// ---------- caveats ----------
#block(
  width: 100%,
  stroke: (left: 2.5pt + accent),
  inset: (left: 10pt, top: 2pt, bottom: 2pt),
)[
  #text(weight: "semibold", size: 9.5pt)[What typstify does not do]
  #v(3pt)
  #for c in data.caveats [
    #text(size: 8.4pt, fill: muted)[• #c] \
  ]
  #v(2pt)
  #text(size: 8pt, fill: muted, style: "italic")[
    Written by the author of typstify. These are the limitations worth knowing before you choose it.
  ]
]
