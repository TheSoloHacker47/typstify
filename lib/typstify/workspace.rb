# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "pathname"

module Typstify
  # A throwaway directory holding everything one compile is allowed to see.
  #
  #   <tmp>/main.typ      the template
  #   <tmp>/data.json     your data
  #   <tmp>/shared/       config.shared_dir, copied
  #
  # Typst is invoked with this directory as its root, so `#read("../.env")`
  # cannot reach your application — not because we filter it, but because the
  # file is not there. That is the whole security model, and it is why the
  # template is copied to the *root* of the workspace rather than nested: Typst
  # resolves relative imports against the importing file, so main-at-root is
  # what makes `#import "shared/branding.typ"` work from any view subdirectory.
  #
  # Every render gets its own workspace, which is also what makes concurrent
  # rendering safe.
  class Workspace
    MAIN = "main.typ"
    DATA = "data.json"

    attr_reader :dir

    # Yields a Workspace and removes it afterwards, exception or not.
    def self.build(source:, data:, config: Typstify.config)
      Dir.mktmpdir("typstify-") do |tmp|
        workspace = new(Pathname.new(tmp), config)
        workspace.write_main(source)
        workspace.write_data(data)
        workspace.copy_shared
        yield workspace
      end
    end

    def initialize(dir, config)
      @dir = dir
      @config = config
    end

    def main_path = dir.join(MAIN)

    def write_main(source)
      File.write(main_path, source, encoding: Encoding::UTF_8)
    end

    # Takes the already-serialised JSON string: validation happens in Document,
    # before a workspace exists.
    def write_data(data)
      File.write(dir.join(DATA), data || "{}", encoding: Encoding::UTF_8)
    end

    # Copy config.shared_dir in, if it exists. Copies rather than symlinks:
    # a symlink inside the root points outside the root, which would hand back
    # exactly the file-system access the workspace exists to remove. Symlinks
    # found in the source tree are skipped for the same reason.
    def copy_shared
      source = @config.template_root.join(@config.shared_dir)
      return unless source.directory?

      destination = dir.join(@config.shared_dir)
      copy_tree(source, destination)
    end

    private

    def copy_tree(source, destination)
      FileUtils.mkdir_p(destination)
      source.children.each do |child|
        next if child.symlink?

        target = destination.join(child.basename)
        if child.directory?
          copy_tree(child, target)
        elsif child.file?
          FileUtils.cp(child, target)
        end
      end
    end
  end
end
