# The spec suite

Four kinds of spec, and one table that matters.

| directory | what lives there |
|---|---|
| `unit/` | one class or module at a time, no Rails |
| `security/` | the properties this gem exists to provide — read these first |
| `requests/` | `render pdf:` through a real Rails stack (`spec/dummy`) |
| `templates/` | the starter pack, compiled and compared against golden text |
| `generators/` | `rails g typstify:install` and `:template` |

## The behaviour contract

The design brief froze twelve scenarios before any code was written. Each one is a named
example, so a gap is visible rather than implied.

| # | scenario | where |
|---|---|---|
| T1 | `render pdf:` in data mode returns a PDF with the right headers | `requests/renderer_spec.rb` |
| T2 | hostile user data renders literally; no file is read | `security/data_mode_spec.rb` |
| T3 | ERB mode with `typ()` is literal; without it, the risk is documented | `security/erb_mode_spec.rb` |
| T4 | `#import "shared/…"` resolves; traversal outside the root raises `PathError` | `security/workspace_isolation_spec.rb`, `unit/resolver_spec.rb` |
| T5 | a compile error raises `CompileError` with Typst's message and line | `unit/document_spec.rb`, `requests/renderer_spec.rb` |
| T6 | every starter template compiles with its sample data | `templates/starter_pack_spec.rb` |
| T7 | twenty concurrent renders stay isolated | `unit/concurrency_spec.rb` |
| T8 | a missing font raises in strict mode, warns otherwise | `unit/fonts_spec.rb` |
| T9 | a vendored Universe package compiles with no network | `unit/package_cache_spec.rb` |
| T10 | `render_and_attach` produces a correct ActiveStorage blob | `requests/active_storage_spec.rb` |
| T11 | a missing template names both paths it tried | `unit/resolver_spec.rb`, `requests/renderer_spec.rb` |
| T12 | unserializable `data:` fails immediately, naming the key path | `unit/data_spec.rb`, `requests/data_under_rails_spec.rb` |

## Goldens

`templates/starter_pack_spec.rb` compares extracted *text*, not PDF bytes: Typst stamps
`/CreationDate` into every document, so byte-identical output across runs is impossible, and a
binary golden is unreviewable anyway. A text diff is something a human can read in a pull
request, which is the entire point of having goldens.

```bash
bundle exec rake goldens    # regenerate, then read the diff before committing it
bundle exec rake previews   # render every starter template to PNG and look at them
```

Design review is not something a spec can do. `rake previews` exists so a person does it.

## Skips

`unit/package_cache_spec.rb` skips itself off Linux. Typst locates vendored packages through
the platform data directory, which only `XDG_DATA_HOME` steers on Linux; macOS uses a fixed
path no environment variable redirects. CI runs that spec in a job with networking disabled,
which is the environment the feature exists for.

Two examples in `unit/ignore_system_fonts_spec.rb` skip on a machine with no system fonts.

## Running one slice

```bash
bundle exec rspec spec/security          # the interesting ones
bundle exec rspec spec/unit              # fast, no Rails
RAILS_VERSION=7.1 bundle install && bundle exec rspec
```
