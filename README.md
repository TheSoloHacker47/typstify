# typstify

> PDF generation for Rails on the [Typst](https://typst.app) engine — the wkhtmltopdf replacement.
> Invoices, reports, certificates: fast, beautiful, accessible (PDF/UA), and no headless Chrome in your Docker image.

[![Gem Version](https://badge.fury.io/rb/typstify.svg)](https://rubygems.org/gems/typstify)
[![CI](https://github.com/TheSoloHacker47/typstify/actions/workflows/ci.yml/badge.svg)](https://github.com/TheSoloHacker47/typstify/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/TheSoloHacker47/typstify/blob/main/LICENSE)

## Why

Your Rails app generates PDFs. Your options until now:

| | problem |
|---|---|
| wicked_pdf / pdfkit | built on **wkhtmltopdf, which is archived and unmaintained** — no security fixes, ancient WebKit |
| grover / Chrome-based | ships a **full browser** in your production image: hundreds of MB, memory spikes, cold starts |
| prawn | hand-positioning a coordinate DSL for every invoice line |

[Typst](https://typst.app) is the Rust-based successor to LaTeX: a markup language that
compiles to PDF in **milliseconds**, reads **JSON natively**, and can emit **PDF/UA-1
accessible PDFs** — which the European Accessibility Act now effectively requires for
machine-generated customer documents. `typstify` makes it feel like Rails.

## Quickstart

```ruby
# Gemfile
gem "typstify"
```

```bash
bundle && rails g typstify:install && rails g typstify:template invoice
```

```ruby
# app/controllers/invoices_controller.rb
def show
  invoice = Invoice.find(params[:id])
  render pdf: "invoices/show",
         data: { number: invoice.number,
                 total: invoice.total.format,
                 line_items: invoice.line_items.map { |li| { name: li.name, qty: li.qty, amount: li.amount.format } } },
         filename: "invoice-#{invoice.number}.pdf"
end
```

```typ
// app/views/invoices/show.typ
#let data = json("data.json")

= Invoice #data.number

#table(
  columns: (1fr, auto, auto),
  [*Item*], [*Qty*], [*Amount*],
  ..data.line_items.map(i => (i.name, str(i.qty), i.amount)).flatten()
)

#align(right)[*Total: #data.total*]
```

That's a complete, styled, paginated invoice. No browser. No dead binaries.

## The data-first design (and why it's safer)

Notice what the template does: it reads your data as **JSON**, it doesn't interpolate strings.
Your Ruby data can contain anything — Typst markup, `#` directives, quotes — and it renders as
literal text, because content never becomes code.

Each render also happens in a fresh temporary directory containing only the template, its
`shared/` partials, and `data.json`. Typst is invoked with that directory as its compile root,
so a template physically cannot read your `.env`, your credentials, or any other view. Not
because we filter the path — because the file is not there.

`spec/security/` asserts both properties directly; they are the specs worth reading first.

Prefer classic ERB? `.typ.erb` templates work too — pass every dynamic value through the
`typ()` escaping helper:

```erb
= Hello <%= typ(@user.display_name) %>
```

But use data mode. Future-you says thanks.

## Everywhere you need a PDF

```ruby
# Background jobs / plain Ruby
pdf_bytes = Typstify.render(template: "reports/monthly", data: payload)

# Mailers
attachments["report.pdf"] = Typstify.render(template: "reports/monthly", data: payload)

# ActiveStorage
Typstify.render_and_attach(user.documents, template: "certificates/completion",
                           data: cert_data, filename: "certificate.pdf")
```

Batch-generating 10,000 invoices in a job? Typst's per-document compile time is milliseconds —
see [`docs/batch-generation.md`](https://github.com/TheSoloHacker47/typstify/blob/main/docs/batch-generation.md) for a Sidekiq/Solid Queue pattern
and the two settings that make output reproducible.

## Starter templates

`rails g typstify:template <name>` for: **invoice** · **receipt** · **report** ·
**certificate**. Each comes with sample data and a preview task:

```bash
rake typstify:preview[invoices/show]
```

which compiles with the bundled `sample_data.json` into `tmp/previews/`, so you can iterate on
design without loading your app's initializers or touching the database. Shared branding (logo,
colours, footer) lives in `app/views/shared/branding.typ` — change it once, every document
updates.

## Accessible PDFs (EAA / ADA)

HTML→PDF pipelines produce untagged PDFs that fail accessibility requirements. Typst supports
PDF/UA-1 output; enable it globally:

```ruby
Typstify.configure { |c| c.pdf_standard = :ua_1 }
```

Also available: `:a_1b`, `:a_2b`, `:a_3b`, `:a_4`, `:pdf_1_7`, `:pdf_2_0`. PDF/UA-1 requires a
document title, so set `#set document(title: "…")` in the template.

If you invoice EU customers, your compliance team will hug you.

## Fonts & Docker (read this before deploying)

Typst uses system fonts plus any directories you configure. The reliable production setup is
vendoring fonts in your app:

```ruby
c.font_paths = [Rails.root.join("app/assets/fonts")]
```

A missing font family fails loudly in development and test (`strict_fonts`, on by default
there) instead of silently substituting a different face in production. Inter ships with the
gem, so the starter templates work with no configuration at all.

Once your fonts are vendored, turn off the system font scan. It costs about **50 ms per
render** — the starter invoice goes from 58 ms to 4 ms:

```ruby
c.ignore_system_fonts = true
```

Typst Universe packages can be vendored into a directory for network-free builds — with a
platform caveat that matters. Full guide: [`docs/fonts-and-docker.md`](https://github.com/TheSoloHacker47/typstify/blob/main/docs/fonts-and-docker.md).

## Configuration

```ruby
# config/initializers/typstify.rb — written by the install generator
Typstify.configure do |c|
  c.template_root = Rails.root.join("app/views")                 # default
  c.shared_dir    = "shared"                                     # partials namespace
  c.font_paths    = [Rails.root.join("app/assets/fonts")]
  c.ignore_system_fonts = true                                   # false by default; see below
  c.package_cache = Rails.root.join("vendor/typst_packages")     # vendored Universe packages
  c.pdf_standard  = :ua_1                                        # nil by default
  c.strict_fonts  = Rails.env.local?                             # the default
  c.on_warning    = ->(warnings, template) { Rails.logger.warn("#{template}: #{warnings}") }
end
```

### What `on_warning` catches, and on which binding

The `typst` binding used to discard the compiler's warnings whenever compilation **succeeded**
— they were only formatted into the message when compilation failed. That is fixed upstream in
[actsasflinn/typst-rb#10](https://github.com/actsasflinn/typst-rb/pull/10), released in
**typst 0.15.1.6**.

| binding | what `on_warning` receives |
|---|---|
| typst ≥ 0.15.1.6 | every compiler warning, from successful and failed compiles alike, with the workspace path rewritten to your template's name |
| typst < 0.15.1.6 | warnings that accompanied a compile *error*, plus this gem's own missing-font check |

The gem detects which it has by capability, not by version string, so upgrading the binding is
all you need to do. The font pre-check stays either way: it runs *before* the compiler, which
is what lets `strict_fonts` fail without paying for a compile. When the binding can report the
same thing itself, the pre-check keeps quiet rather than saying it twice.

## Errors

| | when |
|---|---|
| `Typstify::MissingTemplate` | neither `.typ` nor `.typ.erb` exists; the message lists both paths tried |
| `Typstify::CompileError` | Typst rejected the document; carries its annotated diagnostic and the line, with your template's name substituted for the workspace path |
| `Typstify::FontMissingError` | a template names a font nothing can supply, in strict mode |
| `Typstify::PathError` | a template name resolved outside `template_root` |
| `ArgumentError` | `data:` contains something JSON cannot represent; the message names the key path, e.g. `data.line_items[0].amount` |

## Migrating from wicked_pdf

There's no HTML→Typst converter — you rewrite each PDF view, and that's genuinely fine: most
teams have 2–5 PDF views, and each takes minutes, not hours, in Typst. The side-by-side
walkthrough (a real wicked_pdf invoice vs its Typst version, at a third of the line count):
[`docs/migrating-from-wicked_pdf.md`](https://github.com/TheSoloHacker47/typstify/blob/main/docs/migrating-from-wicked_pdf.md).

## Compatibility

Ruby ≥ 3.1 · Rails 7.1 – 8.1 · Linux & macOS. PDF compilation is done by the excellent
[`typst` gem](https://github.com/actsasflinn/typst-rb) (Rust binding to the Typst compiler) —
this gem is the Rails layer on top, and ships no compiler of its own.

Note: Rails 8.1 requires Ruby 3.4 or newer in practice, because `actionview` uses syntax that
older Rubies cannot parse. The CI matrix pairs them accordingly.

## Related work

[`typst-rails`](https://github.com/durable-oss/typst-rails) by David J. Berube covers similar
ground and appeared around the same time; it supports Rage and Sinatra alongside Rails. This
gem is narrower on purpose — Rails only — and spends that focus on the sandboxed workspace, the
data-mode security model, the starter template pack and PDF/UA output. Worth comparing both
against what you need.

## Contributing

```bash
git clone https://github.com/TheSoloHacker47/typstify && cd typstify
bin/setup && bundle exec rake
```

Template pack contributions especially welcome — new document types need sample data, a spec,
and a golden. See [CONTRIBUTING.md](https://github.com/TheSoloHacker47/typstify/blob/main/CONTRIBUTING.md).

## License

[MIT](https://github.com/TheSoloHacker47/typstify/blob/main/LICENSE). Inter is vendored under the [SIL Open Font License](https://github.com/TheSoloHacker47/typstify/blob/main/fonts/inter/OFL.txt).
Typst itself is Apache-2.0 by the Typst team — go star it.

## More from me

- [scrubber_rb](https://github.com/TheSoloHacker47/scrubber-rb) — fast PII and secret redaction for Ruby, with a Rust core
- [bundler-overrule](https://github.com/TheSoloHacker47/bundler-overrule) — force, ban and swap gem versions in your Gemfile
