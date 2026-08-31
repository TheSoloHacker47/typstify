# frozen_string_literal: true

require "pathname"
require "set"

module Typstify
  # Font resolution, done by us rather than by the compiler.
  #
  # Typst warns about an unknown font family and then quietly substitutes
  # another face — which is how a production invoice ends up in a font nobody
  # chose. We would rather surface that, but the `typst` binding currently
  # discards compiler warnings on a successful compile (it only formats them
  # into the message when compilation *fails*), so there is nothing to listen
  # to. See the upstream PR linked in the README.
  #
  # Until that lands, we answer the question ourselves: read the family names a
  # template asks for out of its source, and check them against the fonts we
  # can actually see. Cheap, deterministic, and honest about what it covers —
  # it reads static `font:` declarations, not families computed at runtime.
  module Fonts
    # Faces compiled into the Typst binary; always available, never on disk.
    EMBEDDED = [
      "libertinus serif",
      "new computer modern",
      "new computer modern math",
      "deja vu sans mono",
      "dejavu sans mono"
    ].freeze

    # `font: "Inter"` or `font: ("Inter", "Noto Sans")`
    DECLARATION = /\bfont\s*:\s*(\((?:[^()]*)\)|"(?:[^"\\]|\\.)*")/m
    STRING = /"((?:[^"\\]|\\.)*)"/

    SYSTEM_DIRECTORIES = [
      "/System/Library/Fonts",
      "/System/Library/Fonts/Supplemental",
      "/Library/Fonts",
      "~/Library/Fonts",
      "/usr/share/fonts",
      "/usr/local/share/fonts",
      "~/.fonts",
      "~/.local/share/fonts"
    ].freeze

    EXTENSIONS = %w[.ttf .otf .ttc .otc].freeze

    module_function

    # Families a chunk of Typst source asks for, in declaration order.
    def declared_families(source)
      source.to_s.scan(DECLARATION).flat_map do |(declaration)|
        declaration.scan(STRING).flatten
      end.map(&:strip).reject(&:empty?).uniq
    end

    # Families the compiler will be able to find, downcased for comparison.
    def available_families(font_paths, include_system: true)
      key = [font_paths.map(&:to_s).sort, include_system]
      @available ||= {}
      @available[key] ||= begin
        families = EMBEDDED.dup
        search_paths(font_paths, include_system: include_system).each do |directory|
          families.concat(families_in(directory))
        end
        families.map(&:downcase).uniq.to_set
      end
    end

    # Reset the memoized scan. Fonts installed mid-process are rare; specs are not.
    def reset!
      @available = nil
    end

    # @return [Array<String>] families the template wants and nothing provides
    def missing(source, font_paths, include_system: true)
      available = available_families(font_paths, include_system: include_system)
      declared_families(source).reject { |family| available.include?(family.downcase) }
    end

    # The directories the compiler will look in. Kept in step with
    # `ignore_system_fonts`, so the check never calls a family available that
    # the compiler will not actually reach for.
    def search_paths(font_paths, include_system: true)
      paths = font_paths.map { |path| File.expand_path(path.to_s) }
      paths += SYSTEM_DIRECTORIES.map { |directory| File.expand_path(directory) } if include_system
      paths
    end

    def families_in(directory)
      return [] unless File.directory?(directory)

      Dir.glob(File.join(directory, "**", "*")).flat_map do |path|
        next [] unless EXTENSIONS.include?(File.extname(path).downcase)

        read_families(path)
      end
    rescue SystemCallError
      []
    end

    # Family names out of an SFNT `name` table (nameID 1 and 16).
    def read_families(path)
      File.open(path, "rb") do |file|
        header = file.read(4)
        return [] if header.nil?

        offsets = header == "ttcf" ? collection_offsets(file) : [0]
        offsets.flat_map { |offset| families_at(file, offset) }
      end
    rescue SystemCallError, EOFError
      []
    end

    def collection_offsets(file)
      file.seek(8)
      count = file.read(4).unpack1("N")
      return [] if count.nil? || count.zero? || count > 1024

      Array(file.read(4 * count)&.unpack("N*"))
    end

    def families_at(file, base)
      file.seek(base + 4)
      table_count = file.read(2)&.unpack1("n")
      return [] if table_count.nil? || table_count.zero?

      file.seek(base + 12)
      records = file.read(16 * table_count).to_s
      name_offset = nil
      table_count.times do |index|
        record = records[index * 16, 16]
        break if record.nil?

        name_offset = record[8, 4].unpack1("N") if record[0, 4] == "name"
      end
      return [] if name_offset.nil?

      parse_name_table(file, name_offset)
    end

    def parse_name_table(file, offset)
      file.seek(offset)
      header = file.read(6)
      return [] if header.nil? || header.bytesize < 6

      _format, count, storage = header.unpack("n3")
      records = file.read(12 * count).to_s

      count.times.filter_map do |index|
        record = records[index * 12, 12]
        next if record.nil?

        platform, _encoding, _language, name_id, length, string_offset = record.unpack("n6")
        next unless [1, 16].include?(name_id)

        file.seek(offset + storage + string_offset)
        decode(file.read(length), platform)
      end.compact.uniq
    end

    def decode(bytes, platform)
      return nil if bytes.nil? || bytes.empty?

      string =
        if platform == 3 || platform.zero?
          bytes.force_encoding(Encoding::UTF_16BE).encode(Encoding::UTF_8)
        else
          bytes.force_encoding(Encoding::BINARY).encode(Encoding::UTF_8, Encoding::ISO_8859_1)
        end
      string.strip.empty? ? nil : string.strip
    rescue EncodingError
      nil
    end
  end
end
