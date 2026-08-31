# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `on_warning` now receives every compiler warning, including those from a **successful**
  compile, when running against `typst` 0.15.1.6 or newer. The upstream fix
  ([actsasflinn/typst-rb#10](https://github.com/actsasflinn/typst-rb/pull/10)) has been merged.
  Support is detected by capability rather than by version string, so older bindings keep the
  previous behaviour and no dependency floor moves.

### Changed

- The missing-font pre-check no longer emits a warning of its own when the binding can report
  the same thing with a line and column. It still runs, and still raises under `strict_fonts`
  before the compiler is invoked.
- `FontMissingError` lists only the directories the compiler will actually search: with
  `ignore_system_fonts` on, the system font directories are no longer named as "searched".

## [0.1.0] — 2026-08-31

First release.

### Added

- `render pdf:` renderer for any Rails controller, honouring `data:`, `filename:`,
  `disposition:` and `status:`.
- `Typstify.render` and `Typstify.render_and_attach` for jobs, mailers and ActiveStorage.
- **Data mode**: templates are pure `.typ` and read their input from `data.json`, so user
  content is data rather than source and cannot alter the document.
- **Workspace isolation**: every render compiles in a fresh temporary directory containing only
  the template, its `shared/` partials and `data.json`, with Typst rooted there. Symlinks in the
  shared tree are skipped rather than followed out of the root.
- **ERB mode** (`.typ.erb`) with the `typ()` escaping helper, one spec per escaped character.
- Starter template pack: invoice, receipt, report and certificate, each with sample data and a
  shared `branding.typ`.
- `rails g typstify:install` and `rails g typstify:template <name>`.
- `rake typstify:preview[invoices/show]` and `rake typstify:templates`.
- PDF standard selection: `:ua_1` (PDF/UA-1), `:a_1b`, `:a_2b`, `:a_3b`, `:a_4`, `:pdf_1_7`,
  `:pdf_2_0`.
- Strict font checking: a family a template names but nothing can supply raises
  `FontMissingError` in development and test, and warns in production.
- `ignore_system_fonts`, which skips the operating system's font directories. Worth knowing:
  that scan costs roughly 50 ms per render — the starter invoice goes from 58 ms to 4 ms.
- `package_cache` for vendored Typst Universe packages, for builds with no network.
- Inter (SIL OFL) bundled, so the starter templates render with no configuration.

### Known limitations

- `on_warning` does not fire for warnings from a **successful** compile. The `typst` binding
  discards them; it only formats warnings into the message when compilation fails. The hook
  works for failure-path warnings and for this gem's own font check. Fix opened upstream:
  [actsasflinn/typst-rb#10](https://github.com/actsasflinn/typst-rb/pull/10).
- `package_cache` is effective on Linux, where the platform data directory follows
  `XDG_DATA_HOME`. macOS uses a fixed location that no environment variable redirects.
- Ruby threads do not speed up rendering: the binding holds the GVL through compilation. Use
  processes for throughput.

[Unreleased]: https://github.com/TheSoloHacker47/typstify/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/TheSoloHacker47/typstify/releases/tag/v0.1.0
