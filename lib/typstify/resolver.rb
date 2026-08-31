# frozen_string_literal: true

require "pathname"

module Typstify
  # Turns a template name ("invoices/show") into a file on disk, and refuses to
  # look outside `template_root` while doing it.
  #
  # This is the first of two containment layers. The second — and the one that
  # actually matters — is the workspace: Typst compiles with the tmpdir as its
  # root, so even a template that somehow got resolved elsewhere could not read
  # past it. This layer exists to turn a traversal attempt into a clear error
  # rather than a confusing "file not found".
  class Resolver
    Resolution = Struct.new(:name, :path, :mode, keyword_init: true) do
      def erb? = mode == :erb
    end

    # Data mode wins: a directory holding both show.typ and show.typ.erb
    # renders the safe one.
    EXTENSIONS = { ".typ" => :data, ".typ.erb" => :erb }.freeze

    def initialize(config = Typstify.config)
      @config = config
    end

    # @param name [String] e.g. "invoices/show", with or without extension
    # @return [Resolution]
    # @raise [PathError] if the name points outside template_root
    # @raise [MissingTemplate] if nothing is there
    def call(name)
      stem = name.to_s.sub(/\.typ(\.erb)?\z/, "")
      root = @config.template_root.expand_path

      tried = EXTENSIONS.keys.map { |ext| candidate(root, stem, ext) }

      EXTENSIONS.each_with_index do |(_ext, mode), index|
        path = tried[index]
        return Resolution.new(name: stem, path: path, mode: mode) if path.file?
      end

      raise MissingTemplate.new(name, tried)
    end

    private

    def candidate(root, stem, extension)
      if stem.start_with?("/", "~")
        raise PathError, "Template name #{stem.inspect} must be relative to template_root (#{root})."
      end

      path = root.join("#{stem}#{extension}").expand_path
      unless path.to_s == root.to_s || path.to_s.start_with?("#{root}#{File::SEPARATOR}")
        raise PathError,
              "Template name #{stem.inspect} resolves to #{path}, which is outside " \
              "template_root (#{root}). Path traversal is not allowed."
      end

      path
    end
  end
end
