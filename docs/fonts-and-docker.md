# Fonts, packages and Docker

Two things go wrong when a PDF pipeline meets a container: fonts that are not there, and
packages that need a network. Both are avoidable, and both fail in ways that are easy to miss
until a customer forwards you a document that looks wrong.

## Fonts

### How Typst finds a font

In order: the directories you pass as `font_paths`, then the operating system's font
directories, then a small set of faces compiled into the Typst binary (Libertinus Serif, New
Computer Modern, DejaVu Sans Mono).

A slim Debian or Alpine base image has **no** system fonts. So a template that says
`font: "Helvetica"` renders on your Mac and silently substitutes in production. The document
still generates. It just is not the document you designed.

### What this gem does about it

Typst emits a warning for an unknown family and carries on. The `typst` binding discards
warnings when compilation succeeds, so there is nothing for us to forward. Instead, before each
compile, `typstify` reads the `font: "…"` declarations out of your template and its `shared/`
partials and resolves each family against the fonts it can actually see — parsing the family
name out of every `.ttf`/`.otf`/`.ttc` on the search path.

An unresolved family raises `Typstify::FontMissingError` when `strict_fonts` is on (development
and test, by default) and calls `on_warning` when it is off (production, by default). The
reasoning: you want the build to stop, and you do not want a 500 on a customer's invoice at
2am for a font.

```ruby
Typstify.configure do |c|
  c.strict_fonts = true   # or Rails.env.local?, which is the default
end
```

The check reads static declarations. A family computed at runtime
(`font: if condition { "A" } else { "B" }`) will not be seen — the check is a safety net, not a
type system.

### The reliable setup: vendor the fonts

```
app/assets/fonts/
├── Inter-Regular.ttf
├── Inter-SemiBold.ttf
└── OFL.txt
```

```ruby
Typstify.configure do |c|
  c.font_paths = [Rails.root.join("app/assets/fonts")]
end
```

Now the font is in your repository, in your image, and in your build cache. No base-image
surprises, no `fonts-liberation` package to remember.

Inter is bundled with this gem and always on the search path, so the starter templates work
before you have configured anything. Anything else, vendor.

### Then turn the system scan off

Once every family your templates name lives in `font_paths`, nothing on the system is being
used — and scanning for it costs roughly 50 ms per render:

```ruby
Typstify.configure do |c|
  c.font_paths          = [Rails.root.join("app/assets/fonts")]
  c.ignore_system_fonts = true
end
```

On the starter invoice that takes a render from 58 ms to 4 ms. It is off by default because
turning it on changes which face a template naming `"Helvetica"` receives, so it should be a
decision rather than a surprise. The strict font check honours the same setting: with system
fonts out of scope, a template that names one is reported missing instead of quietly
substituted.

Check the licence before you vendor. SIL OFL fonts (Inter, Source Sans, Noto, IBM Plex) are
fine to redistribute inside an application; several commercial licences are not.

### Alternatively, install fonts in the image

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
      fonts-inter fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*
```

Works, but couples your typography to a distribution's packaging. Prefer vendoring.

### Verifying it in CI

The cheapest possible smoke test, and worth having:

```ruby
# spec/pdfs/fonts_spec.rb
RSpec.describe "PDF fonts" do
  it "resolves every font the invoice names" do
    Typstify.config.strict_fonts = true

    expect { Typstify.render(template: "invoices/show", data: sample) }.not_to raise_error
  end
end
```

## Typst Universe packages

`#import "@preview/cetz:0.3.1": canvas` fetches the package from the network on first use and
caches it. In a build with no egress — which is the sane way to build — that fails.

### Vendoring them

Typst resolves packages from the platform data directory:

```
<data dir>/typst/packages/<namespace>/<name>/<version>/
```

Set `package_cache` and `typstify` points `XDG_DATA_HOME` at it:

```ruby
Typstify.configure do |c|
  c.package_cache = Rails.root.join("vendor/typst_packages")
end
```

```
vendor/typst_packages/
└── typst/packages/preview/cetz/0.3.1/
    ├── typst.toml
    └── ...
```

To populate it, let a machine with a network compile the template once and copy the result out
of `~/.cache/typst/packages` (Linux) or `~/Library/Caches/typst/packages` (macOS), or download
the package from Typst Universe directly. Commit it; that is the point.

### The platform caveat, stated plainly

`XDG_DATA_HOME` is how the underlying `dirs` crate locates the data directory **on Linux**. On
macOS the data directory is `~/Library/Application Support`, fixed, and no environment variable
redirects it. So `package_cache` works in your Docker image and in CI, and is inert on a Mac —
where you have a network anyway and the ordinary cache does the job.

The gem's own offline test (`spec/unit/package_cache_spec.rb`) skips itself on macOS for
exactly this reason, and CI runs it in a job with networking disabled.

### The `@local` namespace

Packages under `@local/…` are never downloaded — Typst only looks on disk. If you are writing
your own shared Typst library across several applications, publish it as a `@local` package in
`package_cache` rather than copying `.typ` files around.

## `#set page` is not the only thing that varies by machine

Two smaller reproducibility notes, both worth knowing before you diff two PDFs and wonder why:

- Typst stamps `/CreationDate` and `/ModDate` into every document, so byte-identical output
  across runs is impossible unless you set `#set document(date: none)`.
- Text shaping depends on the font file, not the font name. Two "Inter" files of different
  versions will lay out differently. Vendoring pins this too.

See [batch-generation.md](batch-generation.md) for the reproducible-output settings in context.
