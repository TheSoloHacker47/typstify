// Minimal branding partial for the dummy app. Proves that shared/ is copied
// into the workspace and that `#import "shared/..."` resolves from a view
// subdirectory (T4).

#let brand-header(title: "") = {
  text(size: 18pt, weight: "bold")[#title]
  line(length: 100%)
}

#let brand-footer() = {
  text(size: 8pt)[Dummy Co.]
}
