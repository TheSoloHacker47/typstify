# Handouts

One-page references, rendered by typstify itself. The tool generates its own
collateral, so each handout doubles as a working demo of the gem: if a document
here looks wrong, that is a bug report.

| Handout | Source |
|---|---|
| [The Rails PDF Stack Decision Guide](rails-pdf-decision-guide.pdf) | [`.typ`](rails-pdf-decision-guide.typ) · [data](rails-pdf-decision-guide.data.json) |

Every handout is compiled with `pdf_standard = :ua_1`, so the output is tagged
PDF/UA-1 and a screen reader can navigate it. `#set document(date: none)` means
the same data renders byte-identically every time.

Built from `X-growth-project/handouts/build.rb`.
