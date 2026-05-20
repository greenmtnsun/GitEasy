# GitEasy — Architecture (UML)

Technical-takeover documentation for **GitEasy v1.5.1**. Three views plus this
walkthrough. Reconciled against the working tree on 2026-05-15 (manifest
`ModuleVersion = 1.5.1`). Source is canonical; no rendered images are committed.

This file is the **skim** deliverable — read it and you have the picture even
without a PlantUML viewer. The `.puml` files are the **render** deliverable.

## How to render

- VS Code: `jebbs.plantuml` extension, `Alt+D` preview on any `.puml`.
- One-off: paste a `.puml` into <https://www.plantuml.com/plantuml>.
- CLI: `java -jar plantuml.jar Docs/UML/*.puml`.

## Stereotype vocabulary (5, consistent across all three views)

| Stereotype | Means |
|---|---|
| `<<command>>` | Public exported command (or a grouped cluster of them) |
| `<<engine>>` | `Invoke-GEGit` — the only thing that shells out to `git` |
| `<<helper>>` | Private `GE`-prefixed helper |
| `<<boundary>>` | External executable or service (git, network remote, user) |
| `<<store>>` | Persistent artifact (`.git`, log files, env, manifest, credential stores) |

---

## 01 — Architecture Overview

[`01-architecture-overview.puml`](01-architecture-overview.puml)

GitEasy is a **clean 4-layer procedural module**, no classes:

1. **Loader** ([GitEasy.psm1](../../GitEasy.psm1)) dot-sources `Private\*` then
   `Public\*` (sorted) and exports exactly 21 functions.
2. **Public command surface** — 21 plain-English commands.
3. **Private helpers** in four roles: the git **engine**, **logging**, **query**
   (repo facts), **safety**.
4. **External boundaries**: the `git` executable, the `.git` repository,
   diagnostic log files, the network remote, and credential stores.

The load-bearing fact: **`Invoke-GEGit` is the single point of contact with
git.** Nothing else in the module spawns `git`. Every behavior, every diagnostic
log step, every failure message funnels through that one helper. If you are
taking this over, that is the first file to read.

## 02 — Internal Call Graph

[`02-internal-call-graph.puml`](02-internal-call-graph.puml)

There is **no single universal spine** — a common but wrong assumption about
this codebase. Commands take one of **three structural paths**:

- **Mutating (7)** — `Save-Work, New-Release, Undo-Changes, Switch-Work,
  Restore-File, New-WorkBranch, Clear-Junk`. These open a log session, then
  call `Assert-GESafeSave` (which itself fans out to `Test-GERepositoryBusy`,
  `Get-GEConflictFiles`, `Get-GERepoRoot`) **before** touching the working
  tree, run git through the engine, and close the session SUCCESS/FAILURE.
- **Logged config / sync (5)** — `Show-Change, Get-Updates, Set-Token, Set-Ssh,
  Reset-Login`. Same log-session bracket, **no** `Assert-GESafeSave`.
  `Set-Token` / `Set-Ssh` additionally gate the remote URL through
  `Test-GERemoteUrlSafe` / `Convert-GERemoteToSsh`.
- **Query / no-session (9)** — `Test-Login, Show-Remote, Show-History,
  Search-History, Show-Releases, Find-CodeChange, Set-Vault, Get-VaultStatus,
  Show-Diagnostic`. These open **no** log session; they lean on the `Get-GE*`
  query helpers and the engine. `Show-Diagnostic` is the outlier — it touches
  **neither** the engine nor a session; it only reads log files.

`Start-GELogSession` resolves the directory via `Get-GELogPath` and prunes
old logs via `Remove-GEOldLog` on open. `Invoke-GEGit` appends a per-step
record via `Add-GELogStep` only when a log session is active.

## 03 — Data Flow

[`03-data-flow.puml`](03-data-flow.puml)

What reads/writes which artifact:

- **`.git` repository** — read/write, exclusively via `Invoke-GEGit` → `git`.
- **Network remote** — `git push` writes, `git fetch`/`ls-remote` reads.
- **Diagnostic log files** (`%LOCALAPPDATA%\GitEasy\Logs` ← `GITEASY_LOG_PATH`
  ← `-LogPath`) — one self-contained file per invocation; written by the log
  session helpers, pruned >30 days, read by `Show-Diagnostic`.
- **Temp commit-message file** — `Save-Work` writes a BOM-free UTF-8 temp file,
  commits with `-F`, deletes it in `finally`.
- **`.psd1` manifest** — `Save-Work -BumpVersion` reads then rewrites the
  `ModuleVersion` line in place.
- **Credential stores** — written by `Set-Token` / `Set-Ssh` / `Set-Vault`,
  read by `Test-Login` / `Get-VaultStatus`. GitEasy never embeds credentials in
  remote URLs; `Test-GERemoteUrlSafe` rejects `scheme://user@host` forms and
  any non-HTTPS/SSH URL.

---

## Takeover findings

Things a new owner should know that are **not** obvious from the code:

1. **Stale example — `Examples/10-What-Is-Not-Wired-Yet.ps1`.** Lists
   New-WorkBranch, Switch-Work, Undo-Changes, Restore-File, Clear-Junk as "not
   wired yet." All five are fully implemented and tested in 1.5.0. The script
   misrepresents current state — delete or invert it.
2. **Dev tooling at repo root.** `Update-GitEasyCommandWiki.ps1` and
   `Update-GitEasyPrivateWiki.ps1` live at the repo root, not in `tools/`,
   mixing maintenance scripts with the module root. Cosmetic, but a new owner
   will not expect generators there.
3. **README version drift.** [README.md](../../README.md) states GitEasy is at
   1.0.0; the manifest and CHANGELOG say 1.5.0. First-impression embarrassment
   on a public repo.
4. **`Invoke-GEGit` mutates global CWD.** It does `Set-Location` into
   `WorkingDirectory` around `& git`, restored in a `finally`. Correct under
   normal use, but it is **not reentrancy/thread safe** — concurrent calls in
   the same runspace would race the working directory. Not a bug today
   (commands are sequential); a constraint to respect if anyone parallelizes.
5. **Engine swallows nothing but throws raw on failure.** `Invoke-GEGit`
   throws a multi-line string containing raw git stdout+stderr when a non-
   `-AllowFailure` call exits non-zero. Public commands catch this and
   substitute plain-English messages — so the plain-English contract depends on
   **every caller** wrapping engine calls. A new command that forgets the
   try/catch leaks raw git output to the user. Not enforced by the type system.
6. **Credential-path test coverage is thin.** `Reset-Login` ~23%, `Show-Remote`
   ~36% line coverage (per `coverage.txt`). The lowest-proven code is on the
   credential surface — the riskiest place for it to be weak. No known failing
   tests; this is under-tested, not broken.
7. **No formal security review on record.** GitEasy shells out to git, parses
   remote URLs, and writes to credential stores, but (unlike ClusterValidator)
   has no adversarial-review artifact. `Test-GERemoteUrlSafe` is the one
   explicit injection guard; there is no systematic CWE pass.

## Verification status

- **Render:** no Java runtime on the author's machine, so the diagrams were
  **not** machine-rendered by an independent CLI. Render is confirmed by the
  author opening each `.puml` in VS Code (`jebbs.plantuml`, Alt+D). A clean
  preview proves syntax; it does **not** validate architectural correctness.
- **Correctness:** owned by the architect pass, not by the author's glance.
  Edges were traced to source; one over-generalized edge (`Cfg → QHelp` for
  all 5 logged commands) was caught and corrected — Show-Change and Get-Updates
  call no `Get-GE*` helpers, so the edge is now scoped to Set-Token / Set-Ssh /
  Reset-Login.

## Honest gaps in this documentation

- **3 views, by request.** This is the technical-takeover 3-view set
  (overview, call graph, data flow), not the suite's 12-diagram canonical set.
  No use-case, deployment, state-lifecycle, sequence, or class-contract
  diagrams. The result-record shapes (`Test-Login`'s pscustomobject, the
  `Invoke-GEGit` `{ExitCode,Output,Stderr}` shape) are **not** diagrammed.
- **Call graph is at command-group granularity.** Edges were traced by reading
  the engine, `Assert-GESafeSave`, `Start-GELogSession`, and grep of all 21
  command call sites, plus full reads of `Save-Work`, `Test-Login`,
  `Show-Diagnostic` as path exemplars. Per-command call *ordering* inside the
  other 18 commands is inferred from the path pattern, not line-verified.
- **Version pin is manual.** Titles carry `(v1.5.0)`; nothing automatically
  checks the pin against the manifest. Update titles in the same commit as any
  `ModuleVersion` bump.
