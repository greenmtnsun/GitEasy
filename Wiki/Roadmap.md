# Roadmap

## Next

- Dedicated behavioral Pester tests for `Assert-GESafeSave`. It currently has
  an AST/private-contract test plus transitive coverage through Save-Work's
  conflict and busy-repo tests, but no behavioral suite of its own.

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
