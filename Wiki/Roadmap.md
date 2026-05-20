# Roadmap

## Next

_(empty — the prior "Next" item, dedicated behavioral tests for
`Assert-GESafeSave`, shipped 2026-05-17 in commit `988857d` as
`Tests/GitEasy.AssertSafeSave.Tests.ps1`. Open architectural work is tracked
under "Takeover findings" in Wiki/Known-Bugs-and-Fixes.md.)_

## Done (reconciled 2026-05-17)

- **Dedicated behavioral tests for `Assert-GESafeSave`** — shipped as
  `Tests/GitEasy.AssertSafeSave.Tests.ps1` (commit `988857d`): 10 tests, real
  temp-repo integration + module-scoped-mock conflict-branch isolation.
- **Credential-surface security review** — formal adversarial pass with three
  fixed findings; see `docs/SECURITY-FINDINGS-2026-05-17.md` and
  `Tests/GitEasy.AuthHardening.Tests.ps1`.

## Done (reconciled 2026-05-16)

On the roadmap and verified complete in the current source:

- **Clean-but-ahead push in Save-Work.** `Public/Save-Work.ps1` (the
  `$isClean -and $aheadCount -gt 0` branch) publishes a clean branch that is
  ahead of upstream, or reports it under `-NoPush`. Test:
  `GitEasy.SaveWork.Tests.ps1` "publishes a clean branch that is ahead of the
  remote".
- **Native git execution centralized in a private GE-prefixed helper.** The
  helper is `Private/Invoke-GEGit.ps1` (the roadmap's "Invoke-GEGitCommand"
  name was never used). No Public command shells git directly; only
  `Invoke-GEGit` and the unavoidable `Test-GEGitInstalled` probe touch git.
- **Comprehensive Save-Work behavioral tests** (`GitEasy.SaveWork.Tests.ps1`).

## Test coverage — formerly "needed", now covered

All in `GitEasy.SaveWork.Tests.ps1`:

- CRLF / LF warnings are not conflicts — "LF-only files do not block save when
  autocrlf is enabled". This is also the concrete native-git-stderr-warning
  case: the LF/CRLF notice is written to stderr and the save still succeeds.
- Real conflicts block Save-Work — "real merge conflicts block save with a
  plain-English message".
- Save-Work -NoPush works — "NoPush leaves work local even when a remote is
  configured".
- Commit messages written without BOM — "commit messages have no UTF-8 BOM".
- Clean-but-ahead branches are pushed — "publishes a clean branch that is
  ahead of the remote".
