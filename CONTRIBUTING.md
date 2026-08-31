# Contributing to typstify

## Getting set up

```bash
git clone https://github.com/TheSoloHacker47/typstify && cd typstify
bin/setup
bundle exec rake        # specs + rubocop
```

`bin/setup` also compiles a hello-world PDF, so you find out immediately if the `typst` binding
did not install cleanly on your platform.

## Testing against another Rails version

There is one Gemfile, parameterised by an environment variable — no appraisal, no generated
lockfiles to keep in step:

```bash
RAILS_VERSION=7.1 bundle install && bundle exec rspec
```

Rails 8.1 needs Ruby 3.4 or newer in practice: `actionview` uses syntax older Rubies cannot
parse, despite the gem declaring `required_ruby_version >= 3.2`. The Gemfile resolves below 8.1
on an older Ruby for that reason, and CI pairs them explicitly.

## What a good pull request looks like

- A spec that fails before your change.
- Comments that explain *why*, where why is not obvious. The codebase leans on this; see
  `lib/typstify/workspace.rb` for the register.
- RuboCop clean (`bundle exec rubocop -a` handles most of it).
- A `CHANGELOG.md` entry under Unreleased.

## Changing anything under `security/`

`spec/security/` encodes the properties this gem exists to provide: data cannot become code,
and a template cannot read outside its workspace. If a change touches `workspace.rb`,
`resolver.rb`, `escaping.rb` or `data.rb`, say in the pull request description what the change
means for those two properties. "No change" is a fine answer; not mentioning it is not.

Note that `spec/security/erb_mode_spec.rb` deliberately asserts *unsafe* outcomes for ERB
without `typ()`. Those examples are documentation of a real risk, not bugs to fix.

## Contributing a template

New document types are the most welcome contribution, and the bar is:

1. `templates/<name>/<name>.typ` — imports `shared/branding.typ`, reads everything from
   `data.json`, interpolates nothing.
2. `templates/<name>/sample_data.json` — realistic, not `foo`/`bar`. This is what people see
   first.
3. Add the name to `Typstify::Generators::TemplateGenerator::AVAILABLE` and to
   `Golden::TEMPLATES`.
4. `bundle exec rake goldens` to record the golden text, and commit the diff.
5. `bundle exec rake previews` and **look at it**. A template that compiles but is ugly is not
   done; the starter pack is the first thing anyone sees of this project.

Every family a template names must resolve against the bundled fonts, or bring its own
open-licence font with the licence file alongside it.

## Reporting a security issue

See [SECURITY.md](SECURITY.md). Please do not open a public issue for anything that lets a
template escape its workspace or lets user data become Typst code.
