# The original build brief

> **Historical document.** This is the specification typstify was built from, written
> before any code existed and preserved unedited. It is published because the brief,
> not the code, was the part that took the thinking.
>
> **It does not describe what shipped.** Read it as a record of intent:
>
> - The gem is called **typstify**. This document calls it `typst-rails` throughout,
>   because the name was still open when it was written. See §1.
> - Paths, namespaces and the directory tree in §5 use the old name.
> - Some decisions were revised once the internals were measured. `on_warning` in
>   particular does not behave as §3 assumes, for reasons documented in the README
>   and CHANGELOG under *Known limitations*.
>
> For what typstify actually does today, read the [README](../README.md) and
> [CHANGELOG](../CHANGELOG.md). Those are authoritative; this is not.

**License:** MIT. **Stack:** pure Ruby Rails engine, delegating compilation to the
existing `typst` binding gem.

---

## 0. Elevator pitch

`typst-rails` is "WickedPDF for the post-wkhtmltopdf era": first-class PDF generation for Rails
built on Typst, the Rust typesetting engine. Controllers get `render pdf:`, templates live in
`app/views` like everything else, data flows in as JSON (injection-safe by construction), and a
starter pack ships professionally designed invoice/receipt/report/certificate templates.

Positioning (this drives every doc you write):
- wkhtmltopdf (the engine under wicked_pdf/pdfkit) is archived and unmaintained.
- Headless-Chrome gems (grover/ferrum-based) mean shipping a browser in your Docker image.
- Typst compiles in milliseconds, has a tiny footprint, ingests JSON natively, and can emit
  accessible (PDF/UA-1) output — an EAA/ADA compliance requirement HTML→PDF stacks can't meet.

**Read before coding:**
- The `typst` binding gem (we depend on it): https://github.com/actsasflinn/typst-rb —
  verify its CURRENT API at build time (`Typst(...)` / `Typst(body:)` → `.compile(:pdf)` →
  `.bytes` / `.write`). If an option we need (fonts dir, root dir, PDF standard) is missing,
  open an upstream PR — do not fork silently.
- Typst language + data loading (`json()`, `csv()`): https://typst.app/docs/
- Typst's own automated-PDF-generation pitch, for background on the problem space:
  https://typst.app/blog/2025/automated-generation/
- Rails renderer/template-handler APIs: `ActionController::Renderers.add`,
  `ActionView::Template.register_template_handler`, `Rails::Engine`.
- WickedPDF's README (the DX we're matching, minus the dead binary).

---

## 1. Naming

The brief opened on the name, because everything downstream depends on it: the require
path, the namespace, the directory layout in §5.

`typst-rails` was the first choice, with `typstify` next. Two checks had to pass before
committing to either: that the name was free on RubyGems, and that the authors of the
`typst` binding gem had not announced an official Rails layer of their own. Colliding
with upstream, or forcing them to rename around us, was not worth a slightly better name.

**`typstify` is what shipped**, and the rest of this document predates that decision.

---

## 2. Goals / non-goals

**Goals:**
- G1. `render pdf:` in any controller with zero config beyond the gem install.
- G2. Two template modes, with **data mode as the blessed default**:
  - *Data mode*: template is pure `.typ`; Ruby data arrives as JSON. User content can never
    change document structure → injection-safe by construction.
  - *ERB mode* (`.typ.erb`): for teams that insist; ships with a mandatory escaping helper.
- G3. Starter template pack (invoice, receipt, report, certificate) that compiles out of the
  box with sample data and looks genuinely good — this is the marketing surface.
- G4. Production honesty: fonts, Docker, Typst Universe package vendoring, and background-job
  batching are documented and tested, not hand-waved.
- G5. Rails 7.1 → 8.1 support, Ruby ≥ 3.1.
- G6. Accessibility: expose Typst's PDF standard selection (PDF/UA-1, PDF/A) if the binding
  supports it; if not, land the upstream PR as part of this project (launch-post material).

**Non-goals:**
- NG1. No HTML→PDF. We never parse HTML/CSS. The migration guide is explicit: you rewrite your
  PDF views in Typst (and shows why that's a one-afternoon upgrade, not a chore).
- NG2. No bundled fonts beyond what templates need (ship 1–2 open-license fonts inside the
  template pack, e.g. Inter, with their licenses vendored).
- NG3. No own Rust binding in v1 — we depend on the `typst` gem. Revisit only if upstream stalls.
- NG4. No PNG/SVG rendering endpoints in v1 (the binding can; we don't wrap it yet).

---

## 3. Public API (frozen — do not change without approval)

### 3.1 Controller

```ruby
class InvoicesController < ApplicationController
  def show
    invoice = Invoice.find(params[:id])
    render pdf: "invoices/show",                    # app/views/invoices/show.typ
           data: InvoiceSerializer.new(invoice).as_json,
           filename: "invoice-#{invoice.number}.pdf",
           disposition: :inline                     # or :attachment (default)
  end
end
```

- `render pdf:` resolves `.typ` first (data mode), then `.typ.erb` (ERB mode).
- Sets `Content-Type: application/pdf`, honors `filename:`/`disposition:`.
- `data:` must be JSON-serializable; it is written as `data.json` into the compile workspace
  and read in the template via `#let data = json("data.json")`.

### 3.2 Template (data mode — the happy path)

```typ
// app/views/invoices/show.typ
#import "shared/branding.typ": brand-header, brand-footer
#let data = json("data.json")

#brand-header(title: "Invoice " + data.number)

#table(
  columns: (1fr, auto, auto),
  [*Item*], [*Qty*], [*Amount*],
  ..data.line_items.map(item => (item.name, str(item.qty), item.amount)).flatten()
)

#align(right)[*Total: #data.total*]
#brand-footer()
```

### 3.3 Standalone (jobs, mailers, scripts)

```ruby
pdf = TypstRails.render(template: "invoices/show", data: payload)   # => PDF as binary String

# Mailer
attachments["invoice.pdf"] = TypstRails.render(template: "invoices/show", data: payload)

# ActiveStorage
TypstRails.render_and_attach(record.documents,
                             template: "invoices/show", data: payload,
                             filename: "invoice-42.pdf")
```

### 3.4 Configuration (`config/initializers/typst_rails.rb`, generated by installer)

```ruby
TypstRails.configure do |c|
  c.template_root  = Rails.root.join("app/views")      # default
  c.shared_dir     = "shared"                           # partials/includes namespace
  c.font_paths     = [Rails.root.join("app/assets/fonts")]
  c.package_cache  = Rails.root.join("vendor/typst_packages")  # vendored Universe packages
  c.pdf_standard   = nil                                # :ua_1 / :a_2b when binding supports it
  c.on_warning     = ->(warnings, template) { Rails.logger.warn(...) }  # compiler warnings surfaced
end
```

### 3.5 Generators

```
rails g typst_rails:install                 # initializer + app/views/shared/branding.typ + fonts note
rails g typst_rails:template invoice        # copies invoice.typ + sample data.json + preview task
rails g typst_rails:template receipt|report|certificate
```

Each generated template ships with `rake typst_rails:preview[invoices/show]` → compiles with
its bundled `sample_data.json` and opens/writes the PDF, so designers iterate without booting Rails.

### 3.6 ERB mode & escaping (the security-sensitive part)

`.typ.erb` templates are ordinary ERB producing Typst source. Interpolating raw user strings
into Typst source is code injection (Typst has file reads and scripting within its sandbox
root). Therefore:
- Provide `typ(value)` helper — escapes Typst-significant characters (`#`, `*`, `_`, `` ` ``,
  `$`, `@`, `<`, `>`, `[`, `]`, `\`, quotes) so content renders literally. Define the exact
  escape table in `escaping.rb` with a spec per character.
- README and generator comments state plainly: prefer data mode; in ERB mode, every dynamic
  value goes through `typ()`.
- Add a `rubocop-typst_rails` custom cop? NO — out of scope. Instead, dev-mode runtime lint:
  when compiling an `.typ.erb` result, warn if the rendered source length differs from the
  template in suspicious `#`-introducing ways — SKIP if unreliable; do not ship false positives.
  (Agent: attempt a simple heuristic; delete it if it flags legit templates.)

### 3.7 Behavior contract (write tests from these)

| # | Scenario | Expected |
|---|----------|----------|
| T1 | `render pdf:` data mode | 200, `application/pdf`, body starts with `%PDF-`, correct Content-Disposition/filename |
| T2 | data mode, user string contains `#read("secret.txt")`, `*bold*`, quotes | appears LITERALLY in extracted PDF text; no file read occurs |
| T3 | ERB mode with `typ()` on the same hostile string | literal output; without `typ()` a spec DOCUMENTS (not asserts safe) the raw behavior so the risk is visible in the suite |
| T4 | `#import "shared/branding.typ"` from a view subdir | resolves against template_root; path traversal (`../../etc`) outside root raises `TypstRails::PathError` |
| T5 | compile error in template (syntax) | raises `TypstRails::CompileError` carrying Typst's message + line, rendered nicely in dev via standard Rails error page |
| T6 | each starter template with its sample data | compiles in CI; assert page count and key strings via `pdf-reader`; golden PDFs regenerated via a rake task, diffs reviewed by humans |
| T7 | 20 threads rendering concurrently | isolated per-render tmpdir workspaces; no cross-contamination; all valid PDFs |
| T8 | missing font referenced by template | compiler warning surfaced through `on_warning` AND raised as `FontMissingError` in strict mode (`c.strict_fonts = true`, default true in dev/test, false in prod) |
| T9 | Typst Universe package import with `package_cache` populated, network blocked | compiles offline (vendoring works) |
| T10 | `render_and_attach` | ActiveStorage blob attached, content type + filename correct |
| T11 | missing template | `TypstRails::MissingTemplate` (message lists both `.typ` and `.typ.erb` paths tried) |
| T12 | `data:` containing non-JSON-serializable object | immediate `ArgumentError` naming the key path, before any compile |

---

## 4. Architecture

```
typst-rails/
├── lib/
│   ├── typst-rails.rb → typst_rails.rb
│   └── typst_rails/
│       ├── version.rb  config.rb  errors.rb
│       ├── engine.rb            # Rails::Engine: registers renderer, template resolution, rake tasks
│       ├── renderer.rb          # ActionController::Renderers.add :pdf
│       ├── document.rb          # TypstRails.render / render_and_attach entry points
│       ├── workspace.rb         # per-render Dir.mktmpdir: template + data.json + shared/ symlinks-or-copies; cleanup ensure'd
│       ├── resolver.rb          # template lookup (.typ / .typ.erb), path-traversal guard (T4)
│       ├── erb_pipeline.rb      # ERB render + typ() helper context
│       ├── escaping.rb          # the escape table + typ()
│       └── warnings.rb          # parse compiler warnings, strict-font handling (T8)
├── lib/generators/typst_rails/{install,template}/...
├── templates/                   # the starter pack (invoice, receipt, report, certificate)
│   └── invoice/{invoice.typ, sample_data.json, preview.png}
├── fonts/inter/                 # vendored open-license font + LICENSE
├── spec/
│   ├── dummy/                   # minimal Rails app (or use combustion gem — agent's choice, justify in PR)
│   ├── requests/  unit/  security/  templates/
├── gemfiles/                    # appraisal: rails_7_1, rails_7_2, rails_8_0, rails_8_1
├── .github/workflows/ci.yml
└── typst-rails.gemspec  Gemfile  Rakefile  README.md  CHANGELOG.md  LICENSE  CONTRIBUTING.md  CODE_OF_CONDUCT.md
```

Key implementation notes:
- **Workspace isolation (T2/T4/T7):** every render copies (not symlinks, on second thought —
  symlinks can escape the root; COPY) the resolved template + `shared_dir` + writes `data.json`
  into a fresh tmpdir, then invokes the `typst` gem with that dir as compile root. Typst's
  sandbox root = workspace, so templates physically cannot read app secrets (T2). Benchmark the
  copy cost; if shared/ is big, copy lazily only files the template imports (parse `#import`/
  `#include` lines — simple regex is fine, it's an optimization not a security boundary).
- **Compiler invocation:** through the `typst` gem's API (`Typst(main_path).compile(:pdf).bytes`
  or current equivalent). Wrap all binding calls in one adapter class (`document.rb` calls
  `Adapter`) so a binding API change is a one-file fix. Pin the binding version with `~>`.
- **Gemspec deps:** `typst` (~> current), `railties`/`actionpack`/`activesupport` `>= 7.1`.
  `pdf-reader` is dev-only. No other runtime deps.

## 5. Testing & CI

- Request specs against the dummy app for T1/T10/T11; security specs for T2/T3/T4 (these are
  the specs reviewers will read first — make them exemplary); unit specs for escaping table,
  resolver, workspace cleanup (including cleanup-on-exception).
- Template pack specs (T6) with `pdf-reader` text extraction; `rake typst_rails:goldens` to
  regenerate goldens intentionally.
- Matrix: Ruby 3.1–3.4 × Rails 7.1/7.2/8.0/8.1 via appraisal, ubuntu + macos. Note: the `typst`
  gem compiles Rust on install for some platforms — cache aggressively in CI; if install time
  is painful, restrict macos to one Ruby version.
- A `network: none` CI job proving T9 (offline vendored packages).
- RuboCop; coverage ≥ 90% on `lib/`.

## 6. GitHub setup, DoD, launch

Repo conventions identical to the previous two projects (MIT, Covenant, templates, branch
protection, squash merges, Trusted Publishing release workflow on tag).

Description: "PDF generation for Rails on the Typst engine — the wkhtmltopdf replacement.
Invoices, reports, certificates; fast, accessible (PDF/UA), no headless Chrome."
Topics: `rails`, `ruby`, `pdf`, `typst`, `pdf-generation`, `invoices`, `wickedpdf`, `accessibility`.

**Definition of done (v0.1.0):** T1–T12 green across the matrix; the README quickstart works
verbatim in a fresh `rails new` app; all four starter templates render their previews; the
migration guide (`docs/migrating-from-wicked_pdf.md`) exists with a real side-by-side; if the
binding lacked PDF-standard selection, the upstream PR is at least opened and linked.

**Launch checklist (owner):**
- Post: "wkhtmltopdf is dead. Here's how Rails apps generate PDFs now." — invoice screenshots
  above the fold, Docker image size + memory comparison vs a Chrome-based setup, EAA/PDF-UA
  section for the tech leads.
- Separate short post: "Accessible invoices from Rails (EAA/ADA-ready PDFs with Typst)".
- Submit: Ruby Weekly, r/rails, r/ruby, Show HN, Typst Discord/forum + PR to awesome-typst.
- Cross-link all three gems in each README's footer ("More from me") — portfolio compounding.
