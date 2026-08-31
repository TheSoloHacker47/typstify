# frozen_string_literal: true

module Typstify
  # Parsing for the compiler's diagnostic output.
  #
  # The binding gives us diagnostics as one formatted blob — the same codespan
  # rendering the `typst` CLI prints — raised as an ArgumentError:
  #
  #   error: expected expression
  #     ┌─ /tmp/typstify-abc/main.typ:12:8
  #     │
  #  12 │ #let x =
  #     │         ^
  #
  # Warnings share that format and are included *only when compilation fails*,
  # so a successful compile with warnings tells us nothing. Everything here is
  # therefore best-effort presentation, not a contract.
  module Warnings
    BLOCK = /^(?<severity>error|warning):\s*(?<message>.*)$/
    LOCATION = /┌─\s*(?<path>.+?):(?<line>\d+):(?<column>\d+)/

    Diagnostic = Struct.new(:severity, :message, :line, :column, keyword_init: true)

    module_function

    # Split a raw diagnostic blob into its individual errors and warnings.
    def parse(raw)
      text = raw.to_s
      starts = text.enum_for(:scan, BLOCK).map { Regexp.last_match.begin(0) }
      return [] if starts.empty?

      bounds = starts.zip(starts.drop(1) + [text.length])
      bounds.map do |(from, to)|
        chunk = text[from...to]
        header = chunk.match(BLOCK)
        location = chunk.match(LOCATION)
        Diagnostic.new(
          severity: header[:severity].to_sym,
          message: header[:message].strip,
          line: location && location[:line].to_i,
          column: location && location[:column].to_i
        )
      end
    end

    # The workspace is a tmpdir with a random name; showing it to a developer
    # who wrote `app/views/invoices/show.typ` is noise at best. Swap it for the
    # name they used.
    def rewrite_paths(raw, workspace_dir, template_name)
      raw.to_s
         .gsub(%r{#{Regexp.escape(workspace_dir.to_s)}/?main\.typ}, "#{template_name}.typ")
         .gsub(%r{#{Regexp.escape(workspace_dir.to_s)}/?}, "")
         .gsub(%r{[^\s:]*/main\.typ}, "#{template_name}.typ")
    end

    def dispatch(diagnostics, template, config)
      messages = diagnostics.select { |d| d.severity == :warning }.map do |diagnostic|
        diagnostic.line ? "#{diagnostic.message} (line #{diagnostic.line})" : diagnostic.message
      end
      return if messages.empty?

      config.on_warning&.call(messages, template)
    end
  end
end
