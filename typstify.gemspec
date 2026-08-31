# frozen_string_literal: true

require_relative "lib/typstify/version"

Gem::Specification.new do |spec|
  spec.name    = "typstify"
  spec.version = Typstify::VERSION
  spec.authors = ["Nikhil Nelson"]
  spec.email   = ["thesolohacker47@gmail.com"]

  spec.summary = "PDF generation for Rails on the Typst engine — the wkhtmltopdf replacement."
  spec.description = <<~DESC.gsub(/\s+/, " ").strip
    Typstify gives Rails first-class PDF generation on Typst, the Rust typesetting
    engine. Controllers get `render pdf:`, templates live in app/views like every
    other view, and your data arrives as JSON so user content can never change the
    document — injection-safe by construction, compiled in an isolated sandbox
    directory. Ships professionally designed invoice, receipt, report and
    certificate templates, and can emit accessible PDF/UA-1 output for EAA and ADA
    compliance. No headless Chrome, no archived wkhtmltopdf binary.
  DESC

  spec.homepage = "https://github.com/TheSoloHacker47/typstify"
  spec.license  = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "#{spec.homepage}#readme",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir[
    "lib/**/*.{rb,rake}",
    "lib/generators/**/*",
    "templates/**/*.{typ,json}",
    "fonts/**/*.{ttf,otf,txt}",
    "README.md",
    "CHANGELOG.md",
    "LICENSE"
  ]
  spec.require_paths = ["lib"]

  # The Rust compiler binding. Everything typographic happens in here; this gem
  # is the Rails layer on top.
  spec.add_dependency "typst", "~> 0.15"

  spec.add_dependency "actionpack", ">= 7.1", "< 8.2"
  spec.add_dependency "activesupport", ">= 7.1", "< 8.2"
  spec.add_dependency "railties", ">= 7.1", "< 8.2"
end
