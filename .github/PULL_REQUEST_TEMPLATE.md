## What this changes

<!-- One or two sentences. What behaviour is different afterwards? -->

## Why

<!-- The problem, not the patch. -->

## Security properties

<!--
Delete this section if you did not touch workspace.rb, resolver.rb, escaping.rb or data.rb.
Otherwise: what does this change mean for the two claims in SECURITY.md?
  1. Data passed as `data:` cannot become Typst code.
  2. A template cannot read outside its workspace.
"No change" is a fine answer.
-->

## Checklist

- [ ] A spec that fails without this change
- [ ] `bundle exec rake` passes (specs + RuboCop)
- [ ] `CHANGELOG.md` entry under Unreleased
- [ ] For a new template: golden regenerated (`rake goldens`) and previews eyeballed (`rake previews`)
