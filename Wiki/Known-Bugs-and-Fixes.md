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

## Open

- Add Pester coverage for the GitEasy bugs discovered during DBCCPROJECT publishing.

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
- Examples/ scripts default $ProjectRoot to a hardcoded machine path.
  FIXED 2026-05-16 (commit 6397fda): all 11 scripts now default to
  (Split-Path -Parent $PSScriptRoot); the -ProjectRoot parameter stays
  overridable; Examples/README.md de-leaked. Verified CWD-independent.
- HELD (needs its own change, not a drive-by): move Update-GitEasyCommandWiki.ps1
  and Update-GitEasyPrivateWiki.ps1 out of repo root into tools/. Touches a
  Pester test (GitEasy.WikiScripts.Tests.ps1), CONTRIBUTING.md, the PR
  template, and the scripts' own path resolution — a multi-file refactor.
