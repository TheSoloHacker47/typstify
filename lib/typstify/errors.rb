# frozen_string_literal: true

module Typstify
  # Base class for everything this gem raises. Rescue this to catch any
  # Typstify failure without also swallowing unrelated errors.
  class Error < StandardError; end

  # The template could not be found as either `.typ` or `.typ.erb`.
  class MissingTemplate < Error
    attr_reader :template, :tried

    def initialize(template, tried)
      @template = template
      @tried = tried
      super(<<~MSG.strip)
        Could not find a Typst template for #{template.inspect}.

        Tried:
        #{tried.map { |p| "  - #{p}" }.join("\n")}

        Templates live under Typstify.config.template_root
        (#{Typstify.config.template_root}).
      MSG
    end
  end

  # A template path resolved outside `template_root`, or a workspace copy tried
  # to escape its root. Always a bug or an attack; never a normal condition.
  class PathError < Error; end

  # The Typst compiler rejected the document. Carries the compiler's own
  # annotated diagnostic, which points at the offending line.
  class CompileError < Error
    attr_reader :template, :typst_message, :line, :column

    def initialize(template:, typst_message:, line: nil, column: nil)
      @template = template
      @typst_message = typst_message
      @line = line
      @column = column
      location = line ? " (line #{line}#{", column #{column}" if column})" : ""
      super("Typst failed to compile #{template}#{location}:\n\n#{typst_message}")
    end
  end

  # A font family a template asks for is not installed and is not in any
  # configured `font_paths`. Raised only when `strict_fonts` is on.
  class FontMissingError < Error
    attr_reader :families

    def initialize(families, searched)
      @families = families
      super(<<~MSG.strip)
        Missing font #{families.size == 1 ? "family" : "families"}: #{families.map(&:inspect).join(", ")}

        Typst would silently substitute a different face, which changes your
        layout without telling you. Vendor the font and add its directory:

            Typstify.configure { |c| c.font_paths = [Rails.root.join("app/assets/fonts")] }

        Searched:
        #{searched.map { |p| "  - #{p}" }.join("\n")}

        Set `c.strict_fonts = false` to downgrade this to a warning.
      MSG
    end
  end
end
