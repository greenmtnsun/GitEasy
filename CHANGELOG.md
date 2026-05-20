# GitEasy Changelog

All notable changes to this module are recorded here. The format is loosely [Keep a Changelog](https://keepachangelog.com/), and this project follows semantic versioning.

## [Unreleased]

## [1.5.1] - 2026-05-20

### Added

- **`Tests/GitEasy.AssertSafeSave.Tests.ps1`** — dedicated behavioral suite for the `Assert-GESafeSave` guard (the one genuinely-open Roadmap item; previously it had only an AST/private-contract test plus transitive coverage through Save-Work). 10 tests across real temp-repo integration (safe workspace, subdirectory resolution, not-a-workspace, in-progress-merge busy state) and module-scoped-mock isolation of the conflict-only branch (which real git cannot produce without also being "busy"), plus the no-raw-git-jargon contract on every failure message and the Boolean-`$true` success shape.

### Fixed (security)

Adversarial review of GitEasy's credential / remote-auth surface (the 2026-05-15 UML takeover note flagged Reset-Login / Show-Remote coverage gaps with no formal security review on record). Three findings, all fixed in this release; full trust-boundary trace and kill-test mapping in [`docs/SECURITY-FINDINGS-2026-05-17.md`](docs/SECURITY-FINDINGS-2026-05-17.md).

- **F-01 — High — CWE-200 / CWE-532 — embedded credentials in `.git/config` echoed to console and persisted to plaintext log.** `Test-GERemoteUrlSafe` rejects `scheme://user:token@host/...` on the **input** path (`Set-Token`, `Set-Ssh`), but the **read** path (`Get-GERemoteSummary` → `Show-Remote`, and `Reset-Login`'s error message) surfaced whatever was already in `.git/config` with no guard. With a remote of the form `https://x-access-token:ghp_REAL@github.com/o/r.git`, `Show-Remote` returned the live PAT in `Url` and Reset-Login's failure log wrote it verbatim via `AppendAllText` to `%LOCALAPPDATA%\GitEasy\Logs\*.log`. Fixed by `Private/Format-GESafeUrl.ps1` (strips `userinfo@` from a `scheme://` authority; leaves clean URLs and the scp-like SSH form `git@host:path` untouched), wired into `Get-GERemoteSummary` and the Reset-Login error message.
- **F-02 — Medium — correctness + contributes to F-01 — wrong host extracted from credential-embedding URL.** `Reset-Login`'s old regex `^https://(?<Host>[^/]+)/` greedily captured `user:tok@host` as the host, so `git credential reject` was sent the wrong host and silently did nothing while Reset-Login reported success. Fixed by parsing with `[uri]` and requiring `.Scheme -eq 'https'` and non-empty `.Host`; `[uri]` places `user:tok@` in `UserInfo`, never in `.Host`.
- **F-03 — Low — CWE-200 — credential-helper output written verbatim to log.** `Add-GELogStep` calls in `Reset-Login` recorded raw `git credential reject` / `git credential-manager erase` stdout, which can echo `password=` / `secret=` / `token=` / `bearer=` / `Authorization:` lines. Fixed by `Private/Format-GESafeLogLine.ps1` (key-preserving redaction — replaces the value with `[redacted]`, keeps the key for diagnostics), piped into both `Add-GELogStep` calls.

Kill-test suite: `Tests/GitEasy.AuthHardening.Tests.ps1` — 20 tests across the `Format-GESafeUrl` and `Format-GESafeLogLine` unit contexts plus the integration-level "no live secret appears in the failure log" assertion. `Test-GERemoteUrlSafe` is unchanged — it remains the input-path guard by design; the read path is now covered by `Format-GESafeUrl` (input guard vs output sanitiser, deliberately separate).

### Fixed (documentation)

- **All per-version test-count figures audited; two were overstated; no tests were ever lost.** Every version's claimed count was checked by parsing the `Tests/` tree at that version's commit and counting `It` statements with the PowerShell AST (a static count — no execution, no environment dependence). The static count matched the changelog **exactly** for five of seven versions, which validates the method for this codebase (these suites use no runtime-expanding `-TestCases`):

  | Version | Commit | Changelog | Actual (static `It`) | Verdict |
  |---|---|---|---|---|
  | 1.0.0 | `6c9e77e` | 86 | **74** | overstated by 12 — and commit `6c9e77e`'s own subject says "74 total" |
  | 1.1.0 | `afa0a44` | 99 | 99 | exact |
  | 1.3.0 | `54dfb17` | 110 | 110 | exact |
  | 1.4.0 | `8206bc1` | 113 | 113 | exact |
  | 1.4.2 | `bf60a8b` | 264 | 264 | exact |
  | 1.4.3 | `88f5914` | 408 | 408 | exact |
  | 1.5.0 | `34bcd75` | 456 | **435** | overstated by 21 (corroborated by `git diff --stat 34bcd75 HEAD -- Tests/`: only additions since, never deletions/modifications) |

  Only the 1.0.0 (86 → **74**) and 1.5.0 (456 → **435**) narrative figures were wrong, both overstatements in the prose — `git diff` confirms **zero** test files were ever deleted or modified across the whole history, so there is nothing to recover; this is purely a documentation correction. The 1.1.0 entry's "(was 86 in 1.0.0)" back-reference inherits the 1.0.0 error and should read "(was 74)".

  **Current empirically-measured total: 484** (`tools\Run-GitEasyPester.ps1`, Pester 3.4.0, run `bak6780l9`, 2026-05-20: Passed 484 Failed 0) — the 435 baseline at the 1.5.0 tree plus the +19 vault suite (`02b5bbc`), the +10 `Assert-GESafeSave` suite, and the +20 `AuthHardening` suite (this release). Reconciliation arithmetic: 484 − 20 − 10 − 19 = 435.

## [1.5.0] - 2026-05-09

Two new commands fill obvious workflow gaps that surfaced during the dogfood roadmap pass.

### Added

- **`Show-Change`** — the natural counterpart to `Find-CodeChange`. Where Find-CodeChange tells you HOW MANY things changed, Show-Change shows the actual lines added and removed. Returns one structured object per file with `Path` and `Diff`. Switches: `-Path` filters to one file; `-NextSave` shows what is already prepared for the next saved point (default shows the unprepared working-area changes); `-Compact` returns a one-line summary per file instead of full diff text. 6 Pester tests.
- **`Get-Updates`** — fetches peer updates from the published location without merging or changing the working area. Reports how many new saved points were fetched. Use it to peek at peer activity without committing to Save-Work. 5 Pester tests.

### Changed

- Public command surface count is now **21** (was 19).
- Wiki module-version watermark moves to 1.5.0.
- 16 new dedicated unit-test files for the two new commands (per-function generator regenerated). Test count is now **456 Pester 3 tests** passing on Windows PowerShell 5.1 and PowerShell 7+ (was 408). _(Correction — see [Unreleased]: this figure was an estimate; the verified total at this tree is 435. No tests were lost.)_
- `Invoke-PfAudit` reports **40/40 functions as Covered (dedicated)**.

### No-jargon discipline

- Initial draft of `Show-Change` exposed a `-Staged` switch. The audit caught it as a HARD-jargon hit (`staged` is git-specific). Renamed to `-NextSave` ("show changes prepared for the next save"). 0 HARD-jargon hits in 1.5.0.

## [1.4.3] - 2026-05-09

Closes the audit gap from 1.4.2. No public-surface behavior changes.

### Added

- **`Tests\Unit\<Helper>.Tests.ps1` for each of the 19 private helpers** — AST-based contract tests that don't depend on the helper being exported. Each asserts: source file exists, function name matches file name, GE-prefix convention holds, parameters are declared with the right shapes (Mandatory / SwitchParameter / ValidateSet), `[CmdletBinding()]` is present where expected, and comment-based help with `.SYNOPSIS` is present.
- **`tools\Build-PrivateUnitTests.ps1`** — AST-driven generator paralleling `Build-PublicUnitTests.ps1`. Re-runnable; regenerates files in place.

### Changed

- Test count is now **408 Pester 3 tests** passing on Windows PowerShell 5.1 and PowerShell 7+ (was 264 in 1.4.2).
- `Invoke-PfAudit` now reports **38/38 functions as Covered (dedicated)**: 19 public + 19 private. The structural gap is closed.

## [1.4.2] - 2026-05-09

Test coverage improvement triggered by re-running the PesterForge `Invoke-PfAudit` (DR-026) against the current source. No public-surface behavior changes.

### Added

- **`Tests\Unit\<Command>.Tests.ps1` for each of the 19 public commands** — dedicated per-function unit tests asserting each command's contract: it is exported, declares `CmdletBinding`, declares the expected parameters with the right shapes (Mandatory / SwitchParameter / ValidateSet), supports `-WhatIf` / `-Confirm` where the function declares `SupportsShouldProcess`, has a non-empty `.SYNOPSIS`, and ships at least one `.EXAMPLE`. Generated by `tools\Build-PublicUnitTests.ps1` for deterministic regeneration.
- **`tools\Build-PublicUnitTests.ps1`** — AST-driven generator for the per-function unit tests above. Re-runnable; regenerates files in place from the live command metadata.

### Changed

- Test count is now **264 Pester 3 tests** passing on Windows PowerShell 5.1 and PowerShell 7+ (was 113).
- `Invoke-PfAudit` now reports **19/19 public commands as Covered (dedicated)** (was 0/19; all were grouped-only).

### Removed

- **17 broken Pester 5 unit-test stubs in `Tests\Unit\` for the older private helpers.** Those files were generated by the May 5 PesterForge dogfood pass using Pester 5 syntax (`Should -Be`, `Should -Throw`, `Set-ItResult`) which silently fails to run on Pester 3. The audit was crediting them as "Covered (dedicated)" based on file existence and name match without verifying the tests actually executed. Removing exposes the true state: those private helpers are now reported as `Missing` by the audit (transitively covered through the public-command grouped tests, but not asserted by name in any test file). A follow-up release could add proper Pester 3 dedicated unit tests for the private helpers; doing so was outside the scope of this release.

### Known gaps after 1.4.1

- 17 private helpers report as `Missing` in `Invoke-PfAudit` (functional coverage exists indirectly via public-command tests; no dedicated unit-test file).
- `Get-GELogPath` and `Remove-GEOldLog` (the newer private helpers) report as `Covered (grouped)` — they have real assertions in `GitEasy.Logging.Tests.ps1` but no per-function file.

## [1.4.0] - 2026-05-03

Three findings from the dogfood test, all fixed.

### Fixed

- **Save-Work -BumpVersion only searched the project root for a manifest** (HARD). The conventional layout for non-trivial PowerShell modules is `<RepoRoot>\<ModuleName>\<ModuleName>.psd1`, which the old logic missed entirely. **Fix:** Save-Work now searches the project root plus one level deep, prefers a manifest whose name matches its parent folder (the conventional pattern), then falls back to a root-level manifest, then to any nested manifest found. Tested with the standard nested layout.
- **Find-CodeChange: Status field truncated in default console rendering** (MEDIUM). The default `Format-Table` view squeezed a multi-element `Status` array into a single column and clipped it. Operators had to know to access `$obj.Status` directly. **Fix:** added `Format\GitEasy.format.ps1xml` with a clean default Table view that shows just the counts (Branch, Clean, Total, Staged, Unstaged, Untracked, Repository). Pipe to `Format-List` for the full Status, DiffStat, and StagedDiffStat arrays. The returned object now carries `PSTypeName = 'GitEasy.CodeChange'` so the format file applies cleanly.
- **Find-CodeChange: UntrackedCount inflated when an untracked directory contained multiple files** (LOW-MEDIUM). Git's behavior here depends on the `core.untrackedfiles` config — with `all`, an untracked directory shows one line per file inside; with `normal` (the conventional default), the directory collapses to one entry. **Fix:** `Get-GECodeChange` now pins `--untracked-files=normal` on the underlying `git status` call so the count is deterministic regardless of user config. An untracked folder with 7 files reports `UntrackedCount = 1`.

### Changed

- Module manifest now declares `FormatsToProcess = @('Format\GitEasy.format.ps1xml')`.
- Install-GitEasy.ps1 also copies the `Format\` folder to the install location.
- 3 new Pester tests: PSTypeName presence; untracked-folder count semantics; nested-layout BumpVersion.

### Tests

- **113 Pester 3 tests** passing on Windows PowerShell 5.1 and PowerShell 7+ (was 110).

## [1.3.0] - 2026-05-03

Tag/release management is now on the public surface. First gap surfaced by the dogfood test (a sister Claude session running real workflow on a different project) is fixed.

(Note: version jumped from 1.1.0 to 1.3.0 because `Save-Work -BumpVersion -BumpKind Minor` was used on a manifest that had already been hand-set to 1.2.0. No 1.2.0 was tagged or shipped — the commit and tag use 1.3.0.)

### Added

- **`New-Release -Version <ver> -Note <text>`** — creates an annotated release marker (Git tag) at the current saved point, with the note travelling alongside. Publishes by default; `-NoPush` keeps it local. `-Force` overwrites an existing release of the same version. 8 Pester tests cover the happy path, NoPush, overwrite refusal, overwrite with Force, and log-session SUCCESS markers.
- **`Show-Releases`** — lists named releases as structured objects (Repository / Version / Date / Note), newest first. `-Pattern <wildcard>` filters; `-Count` limits. 3 Pester tests.

### Changed

- Public command surface count is now **19** (was 17). The two new commands keep the plain-English contract: no Git terminology in user-facing strings.
- Wiki module-version watermark moves from 1.1.0 to 1.3.0.

### Fixed

- **`tools\Run-GitEasyPester.ps1` and `tools\Install-GitEasy.ps1` now pin Pester 3 explicitly.** When Pester 5 was also installed (e.g., via PSGallery user-scope), `Get-Module -ListAvailable | Sort -Desc | Select -First 1` was picking Pester 5, whose legacy adapter mis-runs Pester 3 syntax tests as 0/N pass. Both scripts now filter `Where Version.Major -lt 4` and load the highest 3.x they find.
- All `{ ... } | Should Not Throw` assertions migrated to the deterministic `try/catch + Should BeNullOrEmpty` pattern. `Should Not Throw` (like `Should Throw`) was misbehaving under interactive elevated PowerShell hosts.
- `Undo-Changes` no longer relies on `ShouldProcess` alone for the destructive-op guard. Now requires explicit `-Force`, `-Confirm`, or `-WhatIf`. Eliminates a host-dependent path where ConfirmPreference auto-approved the action.

### Tests

- **110 Pester 3 tests** passing on Windows PowerShell 5.1 and PowerShell 7+ (was 99).

## [1.1.0] - 2026-05-03

The two parallel GitEasy lines (the V1 daily-driver and the V2 from-scratch reboot) merge into a single module. **There is no longer a V1 or V2 — just GitEasy.** This release absorbs the V2 engine wholesale, plus the seven V1 features that were better or more complete than V2.

### Identity

- Module GUID continues V1's `2e113abf-c0e7-4dfb-9cb1-69476d7541f6` (the previously V1-exclusive line is now the only line).
- Module version is **1.1.0** (continuation of V1's 1.0.1.1, treating the V2 engine adoption as a major upgrade).

### Added (harvested from V1)

- **`Save-Work -BumpVersion -BumpKind <Major|Minor|Build|Revision>`** — auto-bumps the active project's `.psd1` ModuleVersion before saving, and prefixes the saved-point note with the new version.
- **`Save-Work` pre-pull with rebase** — before publishing, Save-Work pulls peer updates and replays your saved point on top, so a teammate's recent push does not block yours. Local changes are bracketed with stash/pop.
- **`Reset-Login` deeper credential clearing** — in addition to `git credential reject`, Reset-Login now also calls `git credential-manager erase` (when the manager helper is configured) and `cmdkey.exe /delete` for several Windows credential targets. Clears the saved login from every place Git might be reading it.
- **`Set-Vault -WriteIgnoreList`** — optional switch that writes a starter `.gitignore` for PowerShell / .NET / SQL projects (build artifacts, IDE leftovers, log files, secret files). Preserves any existing patterns; only appends what is missing.
- **`Search-History -Pattern <text>`** — new public command. Finds every saved point that added or removed a piece of text. Useful for forensic questions ("when did `DROP TABLE` first appear?"). Returns structured objects; `-Patch` includes the change text.
- **`Show-History -Graph`** — optional switch that prints a visual ASCII graph of saved points with branching and merging shown, instead of returning structured objects.
- **`Clear-Junk` switched to `git clean -fdX` engine** — removes files matching your `.gitignore` instead of a hardcoded extension list. With `-Force -Aggressive`, also removes untracked files not matched by `.gitignore`. Tracked files are never touched.

### Changed

- Public-surface count is now **17** (added `Search-History`).
- `Save-Work` flow now includes the pre-pull-with-rebase step before push when an upstream is configured. Failures during the pull abort cleanly and leave your saved work intact.
- Wiki module-version watermark moves from `1.0.0` to `1.1.0`.

### Tests

- **99 Pester 3 tests** passing on Windows PowerShell 5.1 and PowerShell 7+ (was 86 in 1.0.0). _(Correction — see [Unreleased]: 1.0.0 was actually 74, not 86; this 99 figure is itself exact.)_
- 12 new tests covering Search-History, Show-History -Graph, Save-Work -BumpVersion, and Set-Vault -WriteIgnoreList.
- Clear-Junk tests rewritten to exercise the gitignore-aware engine (and the `-Aggressive` switch).

### Notes

- The V1 line previously known as `1.0.1.1` is preserved at the `v1-archive` branch on GitHub for historical reference.
- The V2 development branch `giteasy-v2-refresh` is retired; its tip is now `main`.

## [1.0.0] - 2026-05-03

First feature-complete public surface of the V2 design. Every command is implemented, documented, and directly tested.

### Added

- **Stub-to-real implementations** of `New-WorkBranch`, `Switch-Work`, `Restore-File`, `Undo-Changes`, `Clear-Junk`. All five route through `Invoke-GEGit`, open per-invocation diagnostic log sessions, and throw plain-English errors with log-path callouts.
- **`Show-Diagnostic`** — public command for opening, listing, or browsing the diagnostic log folder.
- **Diagnostic logging architecture** — every public command writes one self-contained log file per invocation. Default location `%LOCALAPPDATA%\GitEasy\Logs`, overridable per call (`-LogPath`) or site-wide (`GITEASY_LOG_PATH`). Logs older than 30 days are pruned automatically.
- **Comment-based help on every function and script** — all 16 public commands, 19 private helpers, and 5 scripts now ship with `.SYNOPSIS`, `.DESCRIPTION`, per-`.PARAMETER`, `.EXAMPLE`, `.NOTES`, and `.LINK` blocks.
- **`Update-GitEasyCommandWiki.ps1`** — generates the public-command wiki pages from CBH source-of-truth, with drift detection, CBH audit, stale-claim flagging, source-hash watermarks, module-version watermark, machine/human section merge, orphan removal, and a `-DryRun` mode.
- **`tools/Audit-PublicJargon.ps1`** — scans the public surface for git-terminology leakage and reports HARD vs SOFT hits.
- **MPL-2.0 LICENSE**, README.md, CONTRIBUTING.md, GitHub Actions CI workflow, issue and PR templates.
- **86 Pester 3 tests** covering every public command directly, plus the logging helpers. All pass on Windows PowerShell 5.1 and PowerShell 7+. _(Correction — see [Unreleased]: the real count at this commit is 74, matching commit `6c9e77e`'s own "74 total". The "86" was an overstatement; no tests were lost.)_

### Changed

- `Save-Work` reconciled — clean-but-ahead branches are now published; commit messages are written without UTF-8 BOM; native-Git stderr no longer triggers false failures; routes every Git call through `Invoke-GEGit`; produces plain-English errors with log paths.
- `Assert-GESafeSave` rewritten to use `Test-GERepositoryBusy` and `Get-GEConflictFiles`; throws plain-English on every failure mode.
- `Invoke-GEGit` now captures stdout and stderr separately, so warnings (LF/CRLF, etc.) cannot poison parsed output. Optional `-LogPath` plumbing.
- `Update-GitEasyPrivateWiki.ps1` reads CBH from inside function bodies (the standard PowerShell location). Pages whose helper has been deleted from source are now removed automatically.
- Per-page source-hash watermarks added to every public-command wiki page.
- Module-version watermark added to `Public-Commands.md`.
- Log filenames now include millisecond precision so rapid-fire invocations no longer collide.

### Removed

- Dead-code helpers `Get-GEStatus.ps1` and `Get-GEUpstreamBranch.ps1` (zero callers).
- Stub bodies on the five remaining commands.

### Fixed

- Pester 3 `Should Throw` is broken on PowerShell 7. Tests now use `try/catch` + `Should Not BeNullOrEmpty`, which works on both PS 5.1 and PS 7.
- HARD-jargon regression in `Save-Work` ("detached") and in `Switch-Work` ("stash"). Both translated to plain English.

## [0.9.0] - 2026-04-24

Initial V2 baseline. Public command surface defined; many commands stubbed; Pester harness and read-only commands wired.

### Added

- Module manifest with classic GitEasy public command names.
- Pester test harness, manifest sanity tests.
- Core helpers: `Get-GERepoRoot`, `Get-GEBranchName`, `Get-GECodeChange`, `Invoke-GEGit`.
- Initial `Save-Work` (later reconciled in 1.0.0).
- Read-only commands: `Find-CodeChange`, `Show-History`, `Show-Remote`.
- Authentication-setup commands: `Set-Token`, `Set-Ssh`, `Set-Vault`, `Get-VaultStatus`, `Test-Login`, `Reset-Login`.
- Initial wiki pages and architecture docs.
