# frozen_string_literal: true

# Typstify — PDF generation on the Typst engine.
# https://github.com/TheSoloHacker47/typstify

Typstify.configure do |c|
  # Where .typ templates live. They are views like any other.
  c.template_root = Rails.root.join("app/views")

  # Subdirectory of template_root copied into every compile, so
  # `#import "shared/branding.typ"` resolves from any template.
  c.shared_dir = "shared"

  # Extra font directories. The gem's bundled Inter is always on the path.
  # Vendoring the fonts your templates name is the reliable production setup —
  # see docs/fonts-and-docker.md.
  # c.font_paths = [Rails.root.join("app/assets/fonts")]

  # Vendored Typst Universe packages, for builds with no network.
  # Effective on Linux (so: in your Docker image); see the same doc for why.
  # c.package_cache = Rails.root.join("vendor/typst_packages")

  # Accessible output. :ua_1 is PDF/UA-1, which the European Accessibility Act
  # effectively requires of machine-generated customer documents.
  # Also available: :a_1b, :a_2b, :a_3b, :a_4, :pdf_1_7, :pdf_2_0.
  # c.pdf_standard = :ua_1

  # Raise instead of warning when a template names a font nothing can supply.
  # Defaults to true in development and test, false in production.
  # c.strict_fonts = Rails.env.local?

  # Where warnings go. See the README for what this currently does and does not
  # catch — the compiler binding drops warnings on a successful compile.
  # c.on_warning = lambda do |warnings, template|
  #   Rails.logger.warn("[typstify] #{template}: #{warnings.join("; ")}")
  # end
end
