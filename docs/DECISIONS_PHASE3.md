# GitEasy — Decision Records, Phase 3 (Hardening + first public release)

Security review, PSGallery publishing prep, license / governance choices.
Phase closed at v1.5.3 / v1.5.4. Bootstrapped retroactively 2026-05-28;
each DR cites the artifact it is sourced from.

---

## DR-012
# Decision Record 012 — Credential-safe URL handling: scrub on every read / log / output path

## Status
DECIDED (retroactive, ratified 2026-05-28; closed at v1.5.2).

## Question
A credential embedded in a remote URL (`https://user:token@host/path`)
will leak anywhere the URL appears — log files, error messages, returned
objects, exception traces. What is the rule for handling URLs on those
paths?

## Context
The v1.5.1 review found three credential-surface bugs (F-01 / F-02 / F-03).
The v1.5.2 review found three sibling bugs (F-04 / F-05 / F-06) that had
the same root cause — regex-based URL parsing that captured a
`user:token@host` segment as the host. The pattern was systemic. The fix
had to be structural, not local.

## Decision
**Every URL on a log / output / error path passes through `Format-GESafeUrl`.
Every argument list passed to `git` is sanitized through `Format-GESafeUrl`
before being echoed in the log step header or thrown error.** The `^`
anchor on `Format-GESafeUrl` was removed at v1.5.2 so it sanitizes URLs
that appear mid-string (e.g. a credentials URL quoted inside a git error
message). `Format-GESafeLogLine` covers HTTP-header-style credential
patterns (`Authorization:`, `Proxy-Authorization:`, etc.).

## Source
- CHANGELOG 1.5.2 — F-04 / F-05 / F-06
- docs/SECURITY-FINDINGS-2026-05-20.md
- Private/Format-GESafeUrl.ps1
- Private/Format-GESafeLogLine.ps1
- Private/Invoke-GEGit.ps1
- Tests/GitEasy.AuthHardening.Tests.ps1

## Phase
3

---

## DR-013
# Decision Record 013 — `Test-GERemoteUrlSafe` is the single accept/reject gate for write-path URLs

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
Reading and scrubbing a credential-embedded URL is reactive — the URL
already exists on disk. How does GitEasy prevent the credential-embedded
URL from being written to `.git/config` in the first place?

## Context
The v1.5.2 fix for F-04 named the rule: `Convert-GERemoteToSsh` and
`Set-Ssh` both call `Test-GERemoteUrlSafe` on the input URL and refuse
non-empty `UserInfo`. The same gate fronts every write-path
(`git remote set-url`, vault round-trips). Parsing uses `[uri]`, not
regex — the v1.5.2 lesson was that regex URL parsing is the root cause,
not a fixable defect.

## Decision
**One write-path gate: `Test-GERemoteUrlSafe`.** Every command that may
cause a URL to be persisted runs it through this gate first, parsing with
`[uri]` and refusing on non-empty `UserInfo`, unknown scheme, or any
shape that does not round-trip cleanly. Refusal is a structured result,
not a throw.

## Source
- CHANGELOG 1.5.2 — defense-in-depth on Set-Ssh
- Private/Test-GERemoteUrlSafe.ps1
- Private/Convert-GERemoteToSsh.ps1
- Tests/Unit/Test-GERemoteUrlSafe.Tests.ps1

## Phase
3

---

## DR-014
# Decision Record 014 — PSGallery metadata is audience-first

## Status
DECIDED (retroactive, ratified 2026-05-28; shipped at v1.5.3).

## Question
The PowerShell Gallery surfaces `Description`, `Tags`, `LicenseUri`,
`ProjectUri`, `IconUri`, and `ReleaseNotes` on the package page. How
should each be populated so a non-developer searching the Gallery finds
GitEasy and immediately recognizes it as for them?

## Context
The default temptation is developer-vocabulary metadata: "Git wrapper",
"PowerShell module for source control", etc. That ranks low for the
target audience. v1.5.3 deliberately rewrote `Description` audience-first
— "Plain-English Git for sysadmins, change managers, and compliance
teams. Five everyday PowerShell commands…" 286 chars (under the 400-char
search-card truncation limit). Tags carry both edition markers
(`PSEdition_Desktop`, `PSEdition_Core`) and audience signals
(`SourceControl`, `VersionControl`, `Automation`, `DevOps`). `LicenseUri`
points at the in-repo `LICENSE` so the displayed license matches the
package contents.

## Decision
**Audience-first.** `Description` named for the target audience under
400 chars. 14 tags including edition markers + audience signals.
`LicenseUri` in-repo (anti-vibe alignment with shipped license text).
`ReleaseNotes` inline plaintext (PSGallery does not render Markdown).
The mapping is locked in `docs/PSGALLERY-METADATA-PLAYBOOK.md` and
asserted by `Tests/GitEasy.PublishReadiness.Tests.ps1` (47 tests).

## Source
- CHANGELOG 1.5.3 — full metadata rewrite
- GitEasy.psd1 (current values)
- docs/PSGALLERY-METADATA-PLAYBOOK.md
- Tests/GitEasy.PublishReadiness.Tests.ps1

## Phase
3

---

## DR-015
# Decision Record 015 — No CLA today; external pull requests not accepted

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
GitEasy is MPL-2.0 (DR-003) so anyone may fork. But may they contribute
back via pull request to this repository?

## Context
The README's "From Keith" section and the 2026-05-22 note are explicit:
"Setting up the right legal paperwork to accept code changes from other
people involves a lawyer, and I'd rather put my time and money into
shipping more useful code than into legal forms I might have to redo.
It's not a permanent stance; I'm just taking it slow." Bug reports as
Issues are welcome; PRs are not reviewed.

## Decision
**No CLA today, no external PRs reviewed today. Bug reports as Issues
are welcome.** This is "closed for now," not bolted. The README note
will change when this changes.

## Source
- README.md "From Keith"
- README.md 2026-05-22 note "Contribution door is closed for now"
- (no .github/CONTRIBUTING.md governance file yet — also by design)

## Phase
3
