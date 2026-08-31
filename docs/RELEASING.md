# Releasing typstify

Two one-time setup steps. After that a release is one tag push.

---

## One-time: add the Trusted Publisher on RubyGems

Trusted Publishing lets GitHub Actions publish using a short-lived OIDC token instead of a
long-lived API key in repository secrets. There is no credential to leak and none to rotate.

If `typstify` has never been published, use the **pending** publisher flow — it reserves the
name and authorises the workflow in one step.

1. Sign in at <https://rubygems.org> as the account that will own the gem.
2. Go to <https://rubygems.org/profile/oidc/pending_trusted_publishers/new> — or: profile menu →
   *Trusted Publishers* → *Create pending publisher*.
3. Fill in exactly these values:

   | Field | Value |
   |---|---|
   | RubyGems gem name | `typstify` |
   | Publisher type | GitHub Actions |
   | Repository owner | `TheSoloHacker47` |
   | Repository name | `typstify` |
   | Workflow filename | `release.yml` |
   | Environment | `release` |

   The environment field must match the `environment: name: release` block in
   `.github/workflows/release.yml`. If you leave it blank on RubyGems, delete the
   `environment:` block from the workflow too — they have to agree.

4. Save.

If the gem is already published, use *Trusted Publishers* on the gem's own page instead of the
pending flow; the fields are the same.

## One-time: create the matching GitHub environment

RubyGems will only accept a token minted from the environment you named.

1. <https://github.com/TheSoloHacker47/typstify/settings/environments>
2. *New environment* → name it `release` → *Configure environment*.
3. Recommended, not required:
   - **Deployment branches and tags**: restrict to *Selected* and add the tag rule `v*`, so a
     token for this environment can only be minted by a run triggered from a version tag.
   - **Required reviewers**: add yourself. Publishing then waits for one click, which is a cheap
     undo button for a mistaken tag.

---

## Releasing

1. Update `lib/typstify/version.rb`.
2. Move the `CHANGELOG.md` entries out of Unreleased into the new version, and update the two
   link references at the bottom.
3. Commit: `git commit -am "Release v0.2.0"`.
4. Dry run first, if you want to see the gem built without publishing it: Actions → Release →
   *Run workflow* → leave `dry_run` checked.
5. Tag and push:

   ```bash
   git tag -a v0.2.0 -m "typstify 0.2.0"
   git push origin main v0.2.0
   ```

The workflow runs the full suite, checks the tag matches `Typstify::VERSION`, builds the gem,
asserts the packaged artifact actually contains the fonts and templates (the file list is
hand-written, so this has bitten people), installs it clean and renders a PDF with it, then
publishes and cuts the GitHub release.

## Publishing by hand

Only if Trusted Publishing is unavailable. It needs an API key with push scope, and your
account's MFA level may require an OTP at the prompt:

```bash
bundle exec rake build
gem push pkg/typstify-0.2.0.gem
```

Then create the GitHub release manually so the tag and the gem stay in step.

## After the first release

The pending publisher converts into a normal Trusted Publisher, manageable at
<https://rubygems.org/gems/typstify/trusted_publishers>.
