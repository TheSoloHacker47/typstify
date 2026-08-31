# frozen_string_literal: true

module Typstify
  # Escaping for ERB mode (`.typ.erb`).
  #
  # In data mode this file is irrelevant: values arrive as JSON and Typst reads
  # them as strings, so they can never become code. ERB mode splices Ruby
  # strings straight into Typst *source*, which means an unescaped value is
  # code injection — Typst can read files and run script inside its root.
  #
  # `typ()` renders any value as literal text by backslash-escaping every
  # character Typst treats as markup.
  module Escaping
    # Order matters only for the backslash, which has to go first so the
    # backslashes introduced below are not escaped a second time.
    SIGNIFICANT = [
      "\\",
      "#",  # code / function call
      "*",  # strong
      "_",  # emphasis
      "`",  # raw
      "$",  # math
      "@",  # reference / package
      "<",  # label open
      ">",  # label close
      "[",  # content block open
      "]",  # content block close
      '"'   # string delimiter in code context
    ].freeze

    PATTERN = Regexp.union(SIGNIFICANT).freeze

    module_function

    # Escape a value so Typst renders it as literal text.
    #
    #   typ('#read("/etc/passwd")') # => '\#read\("/etc/passwd"\)' — printed, not run
    #
    # @param value [Object] anything; converted with #to_s
    # @return [String] Typst source that renders as the original text
    def typ(value)
      value.to_s.gsub(PATTERN) { |char| "\\#{char}" }
    end
  end
end
