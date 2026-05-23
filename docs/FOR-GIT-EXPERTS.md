# GitEasy for Git Experts

You already know Git. Why is this doc here?

GitEasy is a thin, honest wrapper. Nothing in `.git/` is modified that
plain Git wouldn't write itself. Your `.gitconfig`, your `.git/hooks`,
your aliases, and your editor integrations all keep working. After any
GitEasy command, raw Git in the same folder still does what it always
did.

This guide answers the *expert* questions about GitEasy that get in the
way of a beginner reading the main how-to: what does it actually run,
what does it promise, how do I script around it, and what do I need to
know about the safety nets.

For the beginner-facing walkthrough, see
[`HOW-TO-USE-GITEASY.md`](HOW-TO-USE-GITEASY.md). For a side-by-side of
every GitEasy command and the raw `git` calls it makes, see
[`GITEASY-VS-RAW-GIT.md`](GITEASY-VS-RAW-GIT.md).

---

## 1. Why an expert reaches for GitEasy

Three reasons, in roughly the order experts find them useful:

### 1.1 One fewer chance to misspell

`Save-Work 'msg'` collapses the four-command `add` / `commit` /
`pull --rebase` / `push` sequence into one tab-completable verb. No
`git stsatus` retries. Useful for muscle memory; more useful when
you're tired or context-switching between five repos.

### 1.2 A sanitized log of every Git call

Every command writes a single text file to
`%LOCALAPPDATA%\GitEasy\Logs\<command>-<YYYYMMDD-HHMMSS>.log`. Inside:

- The user-facing command and its parameters.
- Every internal `git` call with its exit code.
- Sanitized stdout/stderr. Tokens (`ghp_*`, `glpat-*`, `gho_*`), the
  user-info segment of URLs (`https://user:pass@host/...`), and IPv4
  addresses are stripped *before* anything reaches disk.
- The structured return object the command emitted.

This is the fastest way to answer "what exact `git` command did
GitEasy run, and what did it print?" — no `--verbose` flag hunting,
no `GIT_TRACE=1` reruns.

### 1.3 A drop-in tool you hand to a colleague

When you onboard a junior, a data analyst, or a sysadmin teammate,
you don't have to teach Git. You teach `Save-Work`, `Find-CodeChange`,
`Show-History`. They get the same safety nets you want for yourself
(commit-message validation, half-done-state refusal, credential
scrubbing). When they grow into raw Git, GitEasy is still in the same
folder.

---

## 2. Under the hood

### 2.1 What `Save-Work` actually runs

Without `-NoPush`:

```
1. git rev-parse --git-dir       (verify we're in a repo)
2. git status --porcelain=v1     (collect change list)
3. git diff --check              (detect conflict markers)
4. git add --all                 (stage)
5. git commit -m "<msg>"         (commit, message written without BOM)
6. git pull --rebase             (pull teammates' work)
7. git push                      (publish)
```

Each step is logged with its exit code. Steps 1-3 are guards; steps
4-7 are the work. A non-zero exit at any step short-circuits the rest
and throws a plain-English message naming the failure.

With `-SetUpstream`, step 7 becomes `git push -u origin <branch>`.
With `-NoPush`, steps 6 and 7 are skipped.

### 2.2 Half-done-state refusal

Before any state-changing command, GitEasy checks for in-progress
operations:

```
$gitDir = git rev-parse --git-dir
Test-Path $gitDir\MERGE_HEAD,
          $gitDir\REBASE_HEAD,
          $gitDir\CHERRY_PICK_HEAD,
          $gitDir\REVERT_HEAD,
          $gitDir\BISECT_LOG
```

If any path exists, GitEasy refuses to run and tells you to finish
the operation with raw Git first. This is the "no surprise" promise
— a GitEasy command never stacks on top of a half-resolved merge,
rebase, cherry-pick, revert, or bisect.

### 2.3 The credential-scrubbing rules

Every line written to a log file passes through `Format-GESafeLogLine`:

- Lines whose key matches
  `(?i)password|secret|token|bearer|(?:proxy-)?authorization` are
  replaced with `<key>: [REDACTED]`.
- URLs whose user-info segment matches
  `(?<scheme>[a-zA-Z][a-zA-Z0-9+.-]*://)[^/@]+@` have the user-info
  stripped via `Format-GESafeUrl` (works mid-string, not just at the
  start of a line).
- IPv4 addresses are masked to `x.x.x.x`.

The output of every `git` call passes through this filter before
being written to disk. The user-facing return object passes through
too. The full audit history of the rules lives in
`docs/SECURITY-FINDINGS-2026-05-17.md` and
`docs/SECURITY-FINDINGS-2026-05-20.md`.

### 2.4 What gets sent back to the caller

Every state-changing command returns a `[pscustomobject]` with at
least these properties:

```
Passed       : Boolean   # success flag
Message      : String    # plain-English summary
LogPath      : String    # the diagnostic log file path
```

Save-Work also returns `Pushed`, `BranchName`, and `CommitMessage`.
Test-Login returns `Passed` + `Url` (sanitized). The shape is
documented per command in the CBH — `Get-Help <Command> -Full`.

You can pipe to `Where-Object` and `ForEach-Object` for scripted
control flow. State-changing commands respect `-WhatIf` and
`-Confirm` because they declare
`[CmdletBinding(SupportsShouldProcess)]`.

---

## 3. Coexisting with your existing setup

### 3.1 Raw Git in the same folder

Nothing about GitEasy changes the `.git/` layout. After any GitEasy
command, this still works:

```powershell
git status
git log --oneline -n 20
git reflog
git diff HEAD~1
git rebase -i HEAD~3
git commit --amend
git push --force-with-lease
```

GitEasy adds no hooks, no aliases, no `.gitconfig` entries on its own.

### 3.2 Your `.gitconfig`

Untouched. Your `core.editor`, `user.signingkey`, `pull.rebase`,
`init.defaultBranch`, custom aliases, `includeIf` blocks — all in
effect. GitEasy reads the same config raw Git reads.

If you have `pull.rebase = true` globally, GitEasy's explicit
`pull --rebase` in `Save-Work` becomes a redundant-but-correct
double-spec. No harm.

### 3.3 Your `.git/hooks`

Untouched. `pre-commit`, `commit-msg`, `pre-push`, `post-receive`
— all fire exactly when raw Git would fire them. If your `pre-commit`
runs lint and the lint fails, `Save-Work` reports the failure (with
the hook's stderr in the log) and refuses to commit. No special
configuration needed.

### 3.4 GUI tools

GitEasy and Sourcetree, GitKraken, Fork, VS Code's Git pane,
JetBrains' VCS pane — all coexist without conflict. They all operate
on `.git/` directly. Use whichever is in front of you for the task at
hand; switching tools mid-flow is fine.

### 3.5 LFS, submodules, worktrees

GitEasy does not know about any of these. It will not break them —
your `git lfs` operations run normally, your submodules stay
initialized, your worktrees stay separate. GitEasy commands operate
on the current worktree as if the submodules / LFS pointers / sibling
worktrees were transparent.

What GitEasy *won't* do: `git submodule update`, `git lfs pull`,
`git worktree add`. Use raw Git for those.

---

## 4. Scripting with the return objects

### 4.1 Conditional control flow

```powershell
$r = Save-Work 'release prep' -NoPush
if (-not $r.Passed) {
    Show-Diagnostic
    throw "Halting release: $($r.Message)"
}
```

### 4.2 Bulk operations across repos

```powershell
Get-ChildItem -Directory C:\Projects | ForEach-Object {
    Push-Location $_.FullName
    try {
        if (Test-Path .git) {
            Save-Work 'mass-update template'
        }
    } finally {
        Pop-Location
    }
}
```

GitEasy commands act on the current directory. To operate across
multiple repos, change directory and call again.

### 4.3 -WhatIf and -Confirm

```powershell
Save-Work 'risky push' -WhatIf      # show what would happen
Undo-Changes -Confirm               # ask before each destructive step
```

Most commands respect both. Use `-WhatIf` to dry-run before
unfamiliar operations.

---

## 5. Reading the source

Five entry points to understand the codebase quickly:

- **`Private\Invoke-GEGit.ps1`** — the single place that runs
  `git.exe`. Every Public command goes through this. If you want to
  know "what exact git command did GitEasy run for X?", grep
  `Public\X.ps1` for `Invoke-GEGit -ArgumentList @(...)`.
- **`Private\Format-GESafeUrl.ps1`** and
  **`Private\Format-GESafeLogLine.ps1`** — the credential-scrubbing
  helpers. Both are tiny. Read them if you want to verify the scrub
  rules yourself.
- **`Private\Assert-GESafeSave.ps1`** — the busy-check and conflict
  detector. Refuses to let `Save-Work` proceed if MERGE_HEAD /
  REBASE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG exists.
- **`Private\Test-GERemoteUrlSafe.ps1`** — refuses URLs with embedded
  credentials. Called before any `git remote add` / `set-url`.
- **`Private\Start-GELogSession.ps1`** /
  **`Complete-GELogSession.ps1`** — the per-command log-session
  pattern. Every Public command opens a session at the top and
  completes it in a `finally` block.

Public commands are all in `Public\` — one file per command, 21 files
total.

---

## 6. Override knobs

| Knob | Effect |
|---|---|
| `$env:GITEASY_LOG_PATH` | Override the default log directory. Set before `Import-Module` for module-wide effect. |
| `-LogPath <dir>` | Per-command log directory override (most commands accept it). |
| `-WhatIf` | Dry-run; show actions without executing. |
| `-Confirm` | Prompt before each destructive step. |
| `-NoPush` (`Save-Work`, `New-Release`) | Skip the push step. |
| `-SetUpstream` (`Save-Work`) | Add `-u origin <branch>` on first push. |
| `-Force` (`Undo-Changes`, `Clear-Junk`, `New-Release` overwrite) | Required for destructive paths. |
| `-BumpVersion -BumpKind <Major\|Minor\|Patch>` (`Save-Work`) | Bump the `.psd1` `ModuleVersion` as part of the save. |

---

## 7. Where I'd push you toward raw Git

GitEasy is not the right wrapper for these workflows. Skip it and use
plain Git:

- **Squash-on-merge, interactive rebase, amend.** GitEasy is
  append-only on purpose. `git rebase -i`, `git commit --amend`,
  `git push --force-with-lease` all work in the same folder — just
  not through GitEasy.
- **Cherry-pick or bisect.** Same reason.
- **Submodule updates / worktree management / sparse checkouts.** Use
  raw Git for the structural commands; GitEasy is still fine for
  everyday saves inside the worktree.
- **Multiple remotes (more than `origin`).** `Save-Work` pushes only
  to `origin`. If you need to push to a second remote, do it by hand.
- **Signed commits / LFS / GitHub Apps token auth.** Out of scope.
- **Teams of ten+ with daily merge conflicts.** You want feature
  branches, pull requests, code review, and CI — none of which
  GitEasy automates.

---

## See also

- [`HOW-TO-USE-GITEASY.md`](HOW-TO-USE-GITEASY.md) — beginner-friendly
  walkthrough with infographics.
- [`GITEASY-VS-RAW-GIT.md`](GITEASY-VS-RAW-GIT.md) — every GitEasy
  command shown next to the raw `git` calls it makes.
- [`SECURITY-FINDINGS-2026-05-17.md`](SECURITY-FINDINGS-2026-05-17.md)
  and
  [`SECURITY-FINDINGS-2026-05-20.md`](SECURITY-FINDINGS-2026-05-20.md)
  — formal credential-surface review records. Worth reading if you
  audit code for a living.
