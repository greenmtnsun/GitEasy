# GitEasy — Architecture (UML)

Documentation for **GitEasy v1.5.5**. Twelve diagrams covering the standard
suite-wide set (per DR-016, DECISIONS_PHASE4.md), plus this walkthrough.
Source is canonical; no rendered images are committed.

## Diagram index

| # | File | View |
|---|------|------|
| — | [01-architecture-overview.puml](01-architecture-overview.puml) | Component overview — module + external systems |
| — | [02-internal-call-graph.puml](02-internal-call-graph.puml) | Internal call dependency — three command-group paths |
| — | [03-data-flow.puml](03-data-flow.puml) | Data flow — reads/writes per artifact |
| 4 | [04-use-case.puml](04-use-case.puml) | Use case — actors and what they ask |
| 5 | [05-deployment.puml](05-deployment.puml) | Deployment — workstation, git.exe, remote, creds, logs |
| 6 | [06-trust-boundary.puml](06-trust-boundary.puml) | Trust boundary — F-01..F-06 guards + state guard |
| 7 | [07-activity-save-work.puml](07-activity-save-work.puml) | Activity — Save-Work end-to-end flow |
| 8 | [08-sequence-credential-path.puml](08-sequence-credential-path.puml) | Sequence — Set-Token/Set-Ssh → Test-Login → Reset-Login |
| 9 | [09-sequence-tooling.puml](09-sequence-tooling.puml) | Sequence — Audit-PublicJargon.ps1 end-to-end |
| 10 | [10-class-data-contracts.puml](10-class-data-contracts.puml) | Class — all 21 public command PSCustomObject return shapes |
| 11 | [11-module-dependency.puml](11-module-dependency.puml) | Component — hard/soft/dev deps, external services |
| 12 | [12-state-workspace.puml](12-state-workspace.puml) | State — Save-Work workspace state machine |

Diagrams 01–03 are the original three from the v1.5.3 technical-takeover pass;
the prose walkthrough below covers those three in depth. Diagrams 04–12 were
added 2026-06-04 per DR-016.

---

Technical-takeover documentation for the original three views follows.
Reconciled against the working tree on 2026-05-21 (manifest
`ModuleVersion = 1.5.3`). Source is canonical; no rendered images are committed.

> **1.5.3 reconciliation note.** 1.5.3 is a metadata-only release —
> manifest, tooling, and docs only. The runtime architecture, the
> internal call graph, and the data flow are all unchanged from 1.5.2.
> The three diagrams below got a title-version bump and nothing else.
> New repo surfaces introduced in 1.5.3 (`Assets\icon.png` for the
> PowerShell Gallery sidebar, `tools\Publish-GitEasy.ps1` for the
> publish-pipeline, `tools\Audit-GEUsage.ps1` for the command-usage
> audit, `Tests\GitEasy.PublishReadiness.Tests.ps1` for the manifest
> gate, `docs\FOR-GIT-EXPERTS.md` and `docs\PSGALLERY-METADATA-PLAYBOOK.md`
> for the audience-split docs) are deliberately **not** in the
> diagrams: they are build-time / distribution / documentation
> artifacts, not runtime architecture. The runtime picture stays the
> same five-layer shape (User → Public → Engine/Log/Query/Safety →
> git → .git/Logs/Remote/Creds).

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
  `Get-GEConflictFile`, `Get-GERepoRoot`) **before** touching the working
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

1. **Dev tooling at repo root.** `Update-GitEasyCommandWiki.ps1` and
   `Update-GitEasyPrivateWiki.ps1` live at the repo root, not in `tools/`,
   mixing maintenance scripts with the module root. Cosmetic, but a new owner
   will not expect generators there.
2. **`Invoke-GEGit` mutates global CWD.** It does `Set-Location` into
   `WorkingDirectory` around `& git`, restored in a `finally`. Correct under
   normal use, but it is **not reentrancy/thread safe** — concurrent calls in
   the same runspace would race the working directory. Not a bug today
   (commands are sequential); a constraint to respect if anyone parallelizes.
   Tracked in `Wiki/Roadmap.md` as a deferred refactor.
3. **Engine throws raw stdout/stderr on failure.** `Invoke-GEGit` throws a
   multi-line string containing raw git stdout+stderr when a non-
   `-AllowFailure` call exits non-zero. As of 1.5.2 (F-06), URL-shaped args
   are sanitised in the step header and thrown message; the **body** of
   stdout/stderr is still raw, so any caller that surfaces the body to the
   user must apply its own sanitisation. Public commands catch this and
   substitute plain-English messages — the plain-English contract depends on
   **every caller** wrapping engine calls. Not enforced by the type system.

### Resolved since this document was first written

- **Stale example** `Examples/10-What-Is-Not-Wired-Yet.ps1` → renamed to
  `10-Confirm-Install.ps1` with content that probes a real install.
- **README version drift** (was 1.0.0 vs manifest 1.5.0) → README now tracks
  the manifest watermark; verified at every release.
- **Credential-path test coverage thin** (`Reset-Login` ~23%, `Show-Remote`
  ~36% per old `coverage.txt`) → `Tests/GitEasy.AuthHardening.Tests.ps1` is
  the dedicated kill-test suite for the credential surface (F-01/F-02/F-03
  in 1.5.1; F-04/F-05/F-06 plus F-01/F-02/F-03 edge locks added in 1.5.2).
- **No formal security review on record** → `docs/SECURITY-FINDINGS-2026-05-17.md`
  (1.5.1 — three findings) and `docs/SECURITY-FINDINGS-2026-05-20.md` (1.5.2
  — three findings) are the on-record adversarial-review artifacts.

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

- **Original 3-view gap now closed.** Diagrams 04–12 (added 2026-06-04, DR-016)
  provide the use-case, deployment, trust-boundary, activity, sequence, class,
  state, and dependency views that were absent from the takeover pass.
- **Call graph is at command-group granularity.** Edges in 02-internal-call-graph
  were traced from the engine, `Assert-GESafeSave`, `Start-GELogSession`, and
  grep of all 21 command call sites. Per-command call *ordering* inside the 18
  non-exemplar commands is inferred from the path pattern, not line-verified.
- **No fan-out sequence.** GitEasy operates on one repository at a time; there is
  no per-target fan-out equivalent to ClusterValidator's `Invoke-ClvRemote`.
  Diagram 08 covers the credential single-flow path instead.
- **Save-Work returns void.** Unlike all other public commands, Save-Work writes to
  the host and returns nothing. Diagram 10 notes this; a future version may add
  a result object.
- **PlantUML render verification not performed.** PlantUML is not installed in the
  authoring environment for diagrams 04–12. Use `Alt+D` in VS Code or
  plantuml.com to render-check before treating these as gate-passing artifacts.
- **Version pin is manual.** Titles carry `(v1.5.5)`; nothing in the repo yet
  automatically checks the pin against the manifest. Update titles in the same
  commit as any `ModuleVersion` bump. (The `Test-UmlVersionDrift.ps1` drift
  checker from the suite toolkit can be copied into `tools/` to automate this.)
