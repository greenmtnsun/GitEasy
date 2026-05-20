# Known Bugs and Fixes

## Fixed

- False conflict detection from LF/CRLF warnings.
- Save-Work missing NoPush support.
- Native git stderr caused false PowerShell failures.
- Commit message UTF-8 BOM pollution.
- Save-Work now pushes when the repo is clean but ahead of upstream
  (reconciled 2026-05-16: Public/Save-Work.ps1 + GitEasy.SaveWork.Tests.ps1
  "publishes a clean branch that is ahead of the remote").
- Embedded git-runner logic centralized in a private GE-prefixed helper
  (reconciled 2026-05-16: Private/Invoke-GEGit.ps1; no Public command shells
  git directly).
- Credential leak on the read path — FIXED 2026-05-17. Security review of the
  credential surface (full detail: docs/SECURITY-FINDINGS-2026-05-17.md):
  - F-01 (High, CWE-200/532): an embedded-credential URL already in
    .git/config was surfaced by Show-Remote and written to the diagnostic
    log by Reset-Login. Fixed with Private/Format-GESafeUrl.ps1 applied at
    the read boundary (Get-GERemoteSummary, Reset-Login).
  - F-02 (Medium): Reset-Login's host regex captured "user:tok@host" as the
    host (leaked the secret + cleared the wrong entry). Fixed by parsing the
    host with [uri].
  - F-03 (Low, CWE-200): raw credential-helper stdout was logged. Fixed with
    Private/Format-GESafeLogLine.ps1 filtering password/secret/token/bearer/
    Authorization lines before Add-GELogStep.
  Kill-tests in Tests/GitEasy.AuthHardening.Tests.ps1.
- GitEasy bugs discovered during the DBCCPROJECT publishing dogfood already
  have dedicated Pester coverage (reconciled 2026-05-17 — stale TODO, the
  tests shipped with the fixes in 1.3.0/1.4.0, the line was never struck):
  - 1.4.0 finding "Save-Work -BumpVersion missed nested manifests" →
    GitEasy.Harvest.Tests.ps1:196 "finds and bumps a manifest in the
    conventional <ModuleName>\<ModuleName>.psd1 nested layout".
  - 1.4.0 finding "Find-CodeChange Status truncated in default rendering" →
    GitEasy.ReadOnly.Tests.ps1:96 "Find-CodeChange returns an object with
    PSTypeName GitEasy.CodeChange".
  - 1.4.0 finding "UntrackedCount inflated by multi-file untracked dirs" →
    GitEasy.ReadOnly.Tests.ps1:101 "Find-CodeChange counts an untracked
    directory as 1 entry, not one per file inside".
  - 1.3.0 dogfood gap (tag/release management) → New-Release / Show-Releases,
    covered by GitEasy.Releases.Tests.ps1.
  All pass in the current 464/0 suite (run bitbf459z).

## Open

_(none — all previously-open items reconciled 2026-05-16/17. Genuinely
forward-looking work tracked in Wiki/Roadmap.md and the Takeover findings
below.)_

## Takeover findings (2026-05-15 UML pass)

Detail and traced rationale in [docs/UML/README.md](../docs/UML/README.md).

- Plain-English contract is convention, not enforced: Invoke-GEGit throws raw
  git output; every command must try/catch and substitute friendly text. A new
  command that forgets leaks raw git to the user. Not type-checked.
- Invoke-GEGit mutates global CWD (Set-Location, restored in finally) — correct
  sequentially, not reentrant/thread-safe. Constraint, not a bug today.
- Credential-path coverage thin (Reset-Login ~23%, Show-Remote ~36%) and no
  formal security review on record — the credential surface is both least
  tested and least reviewed; Test-GERemoteUrlSafe is the only explicit guard.
  ADDRESSED 2026-05-17: formal adversarial review done (3 findings, all
  fixed — see Fixed section + docs/SECURITY-FINDINGS-2026-05-17.md); new
  Tests/GitEasy.AuthHardening.Tests.ps1 adds dedicated Reset-Login /
  Show-Remote / helper coverage including embedded-credential kill-tests.
- Examples/ scripts default $ProjectRoot to a hardcoded machine path.
  FIXED 2026-05-16 (commit 6397fda): all 11 scripts now default to
  (Split-Path -Parent $PSScriptRoot); the -ProjectRoot parameter stays
  overridable; Examples/README.md de-leaked. Verified CWD-independent.
- HELD (needs its own change, not a drive-by): move Update-GitEasyCommandWiki.ps1
  and Update-GitEasyPrivateWiki.ps1 out of repo root into tools/. Touches a
  Pester test (GitEasy.WikiScripts.Tests.ps1), CONTRIBUTING.md, the PR
  template, and the scripts' own path resolution — a multi-file refactor.
