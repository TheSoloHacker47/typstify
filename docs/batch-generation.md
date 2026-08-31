# Generating PDFs in bulk

Typst compiles the starter invoice in about **4 ms** once fonts are configured properly, which
changes what is reasonable to do in a background job. Ten thousand invoices is a job, not a
project.

The "once fonts are configured properly" is doing real work in that sentence — see
[Make it fast](#make-it-fast) below, where the same document takes 58 ms instead. This document
covers the shape of the job, the settings that matter, and the ways people accidentally make it
slow.

## The shape

```ruby
class GenerateMonthlyInvoicesJob < ApplicationJob
  queue_as :pdfs

  def perform(billing_period_id)
    period = BillingPeriod.find(billing_period_id)

    period.invoices.find_each(batch_size: 500) do |invoice|
      RenderInvoicePdfJob.perform_later(invoice.id)
    end
  end
end

class RenderInvoicePdfJob < ApplicationJob
  queue_as :pdfs
  retry_on Typstify::CompileError, attempts: 1   # a broken template will not fix itself

  def perform(invoice_id)
    invoice = Invoice.includes(:line_items, :customer).find(invoice_id)

    Typstify.render_and_attach(
      invoice.documents,
      template: "invoices/show",
      data: InvoiceSerializer.new(invoice).as_json,
      filename: "invoice-#{invoice.number}.pdf"
    )
  end
end
```

Fan out one job per document rather than looping inside one job. A single failure then retries
one invoice instead of restarting ten thousand, and your queue's concurrency becomes the
throughput dial.

Works the same on Sidekiq and Solid Queue; neither needs anything special from this gem.

## Reproducible output

Two settings, both in the template, both worth adding before you generate anything you might
later need to regenerate identically:

```typ
#set document(
  title: "Invoice " + data.number,   // also required for PDF/UA-1
  date: none,                        // otherwise Typst stamps the current time
)
```

`date: none` removes `/CreationDate` and `/ModDate`. With it, the same data produces
byte-identical PDFs, which means you can checksum output, deduplicate storage, and diff two
runs meaningfully.

## Make it fast

One setting dominates everything else. Measured on an M-series Mac, compiling the starter
invoice forty times:

| configuration | per document |
|---|---|
| default | 58 ms |
| `c.ignore_system_fonts = true` | **4 ms** |

Scanning the operating system's font directories costs roughly 50 ms **per render**. Once you
have vendored the fonts your templates name — which you should anyway, see
[fonts-and-docker.md](fonts-and-docker.md) — the system fonts are not being used, and in a slim
container there are none to find:

```ruby
Typstify.configure do |c|
  c.font_paths          = [Rails.root.join("app/assets/fonts")]
  c.ignore_system_fonts = true
end
```

Turn it on deliberately: it changes which face a template that names `"Helvetica"` ends up
with. The strict font check follows the same setting, so a family you can no longer reach is
reported rather than silently substituted.

## Concurrency

Every render gets its own temporary workspace, so threads never see each other's data —
`spec/unit/concurrency_spec.rb` runs twenty simultaneous renders and asserts exactly that.

**Threads will not make it faster, though.** The `typst` binding does not release the GVL
during compilation, so Ruby threads serialise through it: measured, eight threads render forty
invoices 1.07× faster than one thread, which is noise. Use threads for correctness of
concurrent requests, not for throughput.

For throughput, run more processes — more job workers, or a job per document as above. There is
no shared state to coordinate: no compiler daemon, no browser pool, nothing to warm up. That is
the whole advantage over a Chrome-based pipeline, and it survives being scaled the boring way.

## Two more ways people make this slow

**Serializing inside the template's data by accident.** `data:` walks the whole structure to
validate it. Passing an ActiveRecord model with fifty associations loaded means walking fifty
associations. Pass a serializer's output, and select only the columns you render.

**N+1 queries in the loop.** The PDF is not the slow part; `invoice.customer.address` executed
ten thousand times is. `includes` everything the serializer touches, then measure again.

If you want the actual numbers for your templates:

```ruby
require "benchmark"
data = InvoiceSerializer.new(Invoice.first).as_json
puts Benchmark.measure { 100.times { Typstify.render(template: "invoices/show", data: data) } }
```

## Storage

`render_and_attach` writes through ActiveStorage, which is usually what you want — the blob is
addressable, has a content type, and gets cleaned up with the record. If you are writing
somewhere else, `Typstify.render` gives you the bytes and stays out of the way:

```ruby
Aws::S3::Client.new.put_object(
  bucket: "invoices",
  key: "#{period.year}/#{invoice.number}.pdf",
  body: Typstify.render(template: "invoices/show", data: payload),
  content_type: "application/pdf"
)
```

## Failure handling

`Typstify::CompileError` means the template is wrong, and it will be wrong on the retry too —
fail the job and alert. `Typstify::FontMissingError` is a deployment problem, not a data
problem; catch it at boot with a smoke test rather than in the job. An `ArgumentError` from
`data:` names the key path, which is usually enough to find the serializer bug without opening
the PDF.

```ruby
rescue_from Typstify::CompileError do |error|
  Sentry.capture_exception(error, extra: { template: error.template, line: error.line })
  raise
end
```
