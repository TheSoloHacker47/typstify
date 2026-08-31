# frozen_string_literal: true

namespace :typstify do
  desc "Compile a template with its sample data: rake typstify:preview[invoices/show]"
  task :preview, [:template] do |_task, args|
    require "typstify"
    require "json"
    require "fileutils"

    name = args[:template]
    abort "Usage: rake typstify:preview[invoices/show]" if name.to_s.empty?

    resolution = Typstify::Resolver.new.call(name)
    sample = resolution.path.dirname.join("sample_data.json")
    data =
      if sample.file?
        JSON.parse(File.read(sample, encoding: Encoding::UTF_8))
      else
        warn "No sample_data.json next to #{resolution.path}; rendering with empty data."
        {}
      end

    output = Pathname.new("tmp/previews").join("#{name.tr("/", "-")}.pdf")
    FileUtils.mkdir_p(output.dirname)
    output.binwrite(Typstify.render(template: name, data: data))

    puts "Wrote #{output} (#{output.size} bytes)"
    system("open", output.to_s) if RUBY_PLATFORM.include?("darwin") && ENV["TYPSTIFY_OPEN"] != "0"
  end

  desc "List the templates Typstify can see"
  task :templates do
    require "typstify"
    root = Typstify.config.template_root
    found = Dir.glob(root.join("**", "*.typ{,.erb}"))
    puts "template_root: #{root}"
    if found.empty?
      puts "  (none)"
    else
      found.each { |path| puts "  #{Pathname.new(path).relative_path_from(root)}" }
    end
  end
end
