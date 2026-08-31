# Security policy

## Supported versions

The latest minor release receives security fixes.

## Reporting a vulnerability

Report privately through GitHub's
[security advisory form](https://github.com/TheSoloHacker47/typstify/security/advisories/new),
or by email to thesolohacker47@gmail.com. Please do not open a public issue first.

Expect an acknowledgement within 72 hours, and a fix or a plan within 14 days for anything
confirmed.

## What counts as a vulnerability here

This gem makes two claims. A credible way to break either is a vulnerability:

1. **Data cannot become code.** Anything passed as `data:` reaches the template through
   `data.json` and is read as a string. If you can make a value passed through `data:` execute
   as Typst — call a function, read a file, alter the document's structure — that is a
   vulnerability.
2. **A template cannot read outside its workspace.** Each render compiles in a temporary
   directory holding only the template, its `shared/` partials and `data.json`, with Typst
   rooted there. If you can make a template read a file that was not copied in for it — through
   a symlink, a path in `template_root`, a package import, or anything else — that is a
   vulnerability.

Also in scope: a way to make `Typstify::Resolver` open a file outside `template_root`, and a
way to make `Typstify::Escaping.typ` emit a string that Typst still parses as markup.

## What does not count

- **ERB mode without `typ()`.** `.typ.erb` interpolates Ruby strings into Typst source; an
  unescaped value there is injection by construction, which is why `typ()` exists and why the
  README says to use data mode instead. `spec/security/erb_mode_spec.rb` documents this
  explicitly.
- **Templates authored by an attacker.** A `.typ` file in `app/views` is code you deployed. The
  workspace boundary limits what it can reach, but the threat model is untrusted *data*, not
  untrusted templates.
- **Vulnerabilities in the Typst compiler itself.** Report those to
  [typst/typst](https://github.com/typst/typst); we will pick up the fix when the binding does.

## Credit

Reporters are credited in the changelog and the advisory unless they ask not to be.
