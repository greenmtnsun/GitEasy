# GitEasy — Design Proposal: Resolve-Conflict

**Status:** RATIFIED as DR-017 (2026-06-06). Design accepted; implementation pending.
**Date:** 2026-06-06
**Affects:** DR-010 (amended), DR-005, DR-006, PROJECT_MANIFEST.md, public surface

The design below is accepted (DR-017 in `DECISIONS_PHASE4.md`; DR-010 amended in
`DECISIONS_PHASE2.md`). No shipped code yet — an implementation session follows.
The DR text reproduced at the bottom of this doc is the source that was ratified.
The five items in §9 remain open implementation-detail calls, not blockers.

---

## 1. The problem

Today GitEasy can *see* a conflict but cannot *resolve* one. When two saves
clash, `Assert-GESafeSave` throws:

> Cannot save while there are unfinished conflicts. Resolve these files first: …

and the documented limitation in `GITEASY-VS-RAW-GIT.md` is explicit:

> **No automatic conflict fixing.** When two saves clash, GitEasy stops with a
> friendly message and lists the files. A person must open them and fix the
> conflict.

For the GitEasy audience — the person who *"closed PowerShell because the Git
error felt scarier than the change they were trying to save"* — that dead end is
the single scariest moment the tool can produce. They are now in exactly the
raw-Git swamp the whole module exists to keep them out of. The conflict markers
(`<<<<<<<`, `=======`, `>>>>>>>`), the "ours/theirs/HEAD" vocabulary, and the
"finish the merge" dance are pure jargon.

So the goal: **give the conflicted user a plain-English way out, without
shipping a result we can't stand behind.**

## 2. Goals and non-goals

**Goals**

- One new public command, `Resolve-Conflict`, that resolves an in-progress
  conflict by letting the user choose a side per file (or for all files), in
  plain English.
- Stay inside every Immutable Rule: PowerShell-only, no jargon on the public
  surface, one log file per run, credential scrubbing, structured-result return.
- Be the *sanctioned exception* to DR-010 fail-fast: it is the one command
  allowed to run while the repo is mid-merge with conflicts, because resolving
  is its entire job.

**Non-goals (v1)**

- No intelligent line-level auto-merge of two competing edits to the same line.
  We do not guess. The user picks a side, or keeps both.
- No GUI / external merge-tool dependency on the primary path (see §4, option A
  is an opt-in escape hatch only).
- No LLM-based resolution (see §4, option D — shelved).
- No rebase/cherry-pick conflict support. GitEasy does not create those states
  (DR-010 scope is unchanged for them).

## 3. Why now / what changed

Nothing in the engine changed. What changed is the recognition that DR-010
("refuse, do not muddle through") was written for *unsafe* operations — saving,
switching, branching — where doing nothing is safer than doing something. A
**resolver is the opposite case**: doing nothing leaves the user stuck in the
scary state; doing something *deterministic and user-chosen* is the relief.
DR-010 stays the law for `Save-Work` / `Switch-Work` / `New-WorkBranch`;
`Resolve-Conflict` is carved out as the deliberate exception.

## 4. Options considered

The full scoring matrix lives in the session that produced this doc; summary:

| Option | What "resolve" means | Verdict |
|---|---|---|
| **A. Wrap `git mergetool` / VS Code 3-way / KDiff3** | Hand off to a GUI tool, then finish the merge | Most *correct*, worst *fit*. Breaks no-jargon/no-raw-output the moment the GUI opens; assumes a tool the target user doesn't have. **Keep only as an opt-in expert escape hatch.** |
| **B. A specific third-party resolver** | Depends on the tool | Not evaluated — no specific tool named. Re-open if one is chosen. |
| **C. Strategy-based (keep mine / keep theirs / keep both)** ⭐ | Per-file or whole-merge policy via Git's own `checkout --ours/--theirs` and `merge-file --union` | **Recommended primary.** No new dependency, deterministic, MPL-clean, maps directly to plain-English choices. The "preexisting resolver" here is Git's own merge machinery. |
| **D. LLM-based (Claude API)** | Send conflicted hunks to a model, apply the merged result | **Shelved.** Non-deterministic; can silently produce a *wrong* merge that still compiles — the worst failure mode for a tool whose promise is relief. Also ships user source off-box (against the scrub-before-logging ethos) and depends on the env network policy. If ever revisited: suggest-only, never auto-apply, opt-in. |

Decision: **C primary, A as an opt-in flag, D shelved.**

## 5. Proposed command: `Resolve-Conflict`

### 5.1 Plain-English shape

```powershell
Resolve-Conflict                       # Show what's conflicted, ask per file
Resolve-Conflict -KeepMine             # Take my version for every conflicted file
Resolve-Conflict -KeepTheirs           # Take the other (published/peer) version for every file
Resolve-Conflict -KeepBoth             # Keep both sides where it makes sense (text only)
Resolve-Conflict -File 'README.md' -KeepMine
Resolve-Conflict -OpenInTool           # Opt-in escape hatch: hand off to the user's merge tool (option A)
```

With no switch and no `-File`, the command **lists** the conflicted files and
the per-file choices and returns — it does **not** prompt interactively in v1
(interactive prompting is harder to test under Pester 3 and harder to script;
listing + explicit switch keeps the contract clean). The listing tells the user
exactly which command to run next, in GitEasy's house style.

### 5.2 Vocabulary mapping (the jargon-removal table)

This is the heart of staying inside DR-001. Raw Git terms never reach the user:

| Git reality | Plain-English surface |
|---|---|
| `--ours` (HEAD, your current work) | **"my version"** |
| `--theirs` (the incoming/published side) | **"the published version"** / **"the other version"** |
| union merge | **"keep both"** |
| `git add` + `git commit --no-edit` to finish | (invisible — "finished saving the merge") |
| conflict markers `<<< === >>>` | never shown |

> ⚠️ **Open question for Keith (plain-English call):** the exact wording of
> "the other version." In the `Save-Work` peer-clash path it is a teammate's
> *published* change, so "the published version" is accurate. In a local
> two-branch merge it's "the other working area's version." Proposal: pick
> wording at runtime from context, defaulting to "the other version."

### 5.3 ⚠️ Correctness landmine: which side is "mine"?

`git checkout --ours` means **HEAD**. During a normal **merge**, HEAD is the
user's current branch — so `--ours` = "my version". **But during a rebase the
mapping is reversed.** GitEasy never rebases, and its only conflict source is
the merge that `Save-Work` triggers when it pulls peer updates before pushing
(`Save-Work.ps1:333`). **Therefore implementation MUST confirm that the
pull GitEasy performs is a merge, not a rebase** (i.e. not `pull.rebase=true`
in the user's config). If a rebase is ever possible, the ours/theirs labels
silently invert and "my version" would take the wrong side — a data-loss-class
bug. Implementation gate: detect rebase-in-progress and refuse with a
plain-English "open this in your merge tool" pointer rather than guess.

### 5.4 Parameters

| Parameter | Type | Notes |
|---|---|---|
| `-File` | string[] | Limit to specific file(s). Default: all conflicted files. |
| `-KeepMine` | switch | Take HEAD side (`checkout --ours`). |
| `-KeepTheirs` | switch | Take incoming side (`checkout --theirs`). |
| `-KeepBoth` | switch | Union merge (text files only). |
| `-OpenInTool` | switch | Opt-in option-A escape hatch; launches the user's configured tool, then returns (does not auto-finish). |
| `-LogPath` | string | Override log dir, per house convention. |
| (`-WhatIf`/`-Confirm`) | | Via `[CmdletBinding(SupportsShouldProcess)]` — DR-005 requires a structured result on the WhatIf path too. |

`-KeepMine` / `-KeepTheirs` / `-KeepBoth` / `-OpenInTool` are mutually exclusive
(parameter sets). Choosing none + no `-File` = list-and-explain mode.

### 5.5 Behaviour (Steps: blueprint, house style)

1. Probe for the project folder root and start a diagnostic log session
   (`Start-GELogSession`, DR-006).
2. Confirm a conflict actually exists (`Get-GEConflictFile`). If none, return a
   plain-English "nothing to resolve" result and stop.
3. **Refuse the unsupported state:** if a *rebase* is in progress (not a merge),
   stop with a plain-English pointer to the expert escape hatch (see §5.3).
4. In list-mode (no strategy switch): print the conflicted files and the exact
   follow-up commands; return a structured result; stop.
5. For each targeted file, apply the chosen strategy via Git plumbing (§5.6),
   staging each resolved file as it goes.
6. When **every** conflicted file is resolved and staged, finish the merge
   (`git commit --no-edit`). If some files remain unresolved (e.g. user only
   passed `-File`), do **not** finish — return a result listing what's left.
7. Return a structured result naming each file and the choice applied.

### 5.6 Git plumbing per strategy

- **Keep mine:** `git checkout --ours -- <file>` → `git add -- <file>`
- **Keep theirs:** `git checkout --theirs -- <file>` → `git add -- <file>`
- **Keep both:** `git merge-file --union` against the three stages, or
  re-materialise via `git show :1:/:2:/:3:` stages and union them, then
  `git add`. Text-only; see edge cases.
- **Finish:** when no unmerged paths remain → `git commit --no-edit`
  (completes the in-progress merge with Git's default merge message).
- **Open in tool (opt-in):** `git mergetool -- <file>` with raw output routed to
  the log, never the console; on return, re-check conflict state.

All `git` calls go through `Invoke-GEGit` so credential scrubbing
(`Format-GESafeUrl`, DR-012/013) and log capture happen automatically.

### 5.7 Edge cases that the implementation must handle (not hand-wave)

- **Add/delete conflicts** (one side modified, the other deleted): `checkout
  --ours/--theirs` can fail. "Keep mine/theirs" must translate to `git add` vs
  `git rm` depending on which side exists. Tests required.
- **Both-added** (same path created on both sides, no common base): there is no
  base stage; union is meaningless. Offer mine/theirs only.
- **Binary files:** whole-file replace works for mine/theirs; **`-KeepBoth` is
  invalid** — must refuse per-file with a plain-English message, not produce a
  corrupt union.
- **Partial resolution** (`-File` subset): never auto-finish; report remaining.
- **CRLF/LF noise:** already handled by the existing "treat LF/CRLF warnings as
  expected output" rule in `Save-Work`; reuse it.

## 6. New/changed components

**New public file**
- `Public/Resolve-Conflict.ps1` — the command above, full CBH with `Steps:`
  blueprint (SWARM/swarm-ready requirement).

**Likely new private helpers (GE prefix, DR-002)**
- `Set-GEConflictResolution.ps1` — apply one strategy to one file (the
  ours/theirs/union + add/rm logic, single-sourced).
- `Test-GERebaseInProgress.ps1` — or extend `Test-GERepositoryBusy` to expose
  *which* operation is active, so §5.3 can distinguish merge vs rebase cleanly.
- `Complete-GEMerge.ps1` — finish-the-merge step (`commit --no-edit`) once no
  unmerged paths remain.

**Reused as-is**
- `Get-GEConflictFile`, `Invoke-GEGit`, `Start/Complete-GELogSession`,
  `Add-GELogStep`, `Format-GESafeLogLine`, `Get-GERepoRoot`.

**Manifest / loader (serial-only per SWARM.md)**
- `GitEasy.psd1` → add `Resolve-Conflict` to `FunctionsToExport`; bump
  `ModuleVersion` (proposed **1.6.0** — new public command is a minor bump).
- `GitEasy.psm1` loader needs no change (it dot-sources by folder).

## 7. Tests (Pester 3, DR-009)

- `Tests/Unit/Resolve-Conflict.Tests.ps1` — parameter-set validation, list-mode
  output, WhatIf returns a structured result (DR-005), rebase-in-progress
  refusal, "nothing to resolve" path.
- `Tests/Unit/Set-GEConflictResolution.Tests.ps1` — mine/theirs/union/add-delete
  matrix with mocked `Invoke-GEGit`.
- `Tests/GitEasy.ResolveConflict.Tests.ps1` — integration: build a real temp
  repo, create a genuine conflict, run each strategy end-to-end, assert the
  merge finishes and the right side won. Run serially (SWARM.md integration
  rule).
- Jargon gate: `tools/Audit-PublicJargon.ps1` must stay green against the new
  command's help and output strings.

## 8. Docs to update on implementation

- `docs/GITEASY-VS-RAW-GIT.md` — flip the "No automatic conflict fixing"
  limitation to describe the new plain-English resolve flow (and keep the
  honest caveat that it picks a side, it does not auto-merge competing lines).
- `README.md` — add `Resolve-Conflict` to the command-surface table.
- `PROJECT_MANIFEST.md` — note the DR-010 carve-out so the Immutable Rule and
  the new exception don't read as a contradiction.
- `CHANGELOG.md` — 1.6.0 entry (append-only, serial per SWARM.md).
- Wiki page for the new command (per the per-command Wiki convention).

## 9. Open questions for Keith

1. **Wording** of "the other / published version" (§5.2) — your plain-English
   call.
2. **Interactive prompt** vs **list-then-switch** (§5.1) — proposal is
   list-then-switch for testability; do you want a `-Interactive` mode later?
3. **`-KeepBoth` / union** — ship in v1, or defer (it has the most edge cases)?
4. **`-OpenInTool`** — include the opt-in option-A escape hatch in v1, or leave
   it out entirely?
5. **Version** — 1.6.0 (minor, new command) confirmed?

---

## DR-017 (ratified — now lives in `DECISIONS_PHASE4.md`)

```
## DR-017
# Decision Record 017 — Resolve-Conflict: plain-English, strategy-based conflict resolution

## Status
DECIDED (2026-06-06; Keith ratified). Implementation Phase 4 follow-on.

## Question
GitEasy detects conflicts and refuses (DR-010) but offers the user no way out,
stranding the exact audience the module exists to protect. Should GitEasy add a
conflict resolver, and of what kind?

## Context
DR-010 ("refuse, do not muddle through") was written for unsafe state-changing
operations where doing nothing is safer than doing something. A resolver is the
inverse: doing nothing leaves the user stuck. Four approaches were scored
(mergetool wrap; third-party tool; strategy-based; LLM). See
docs/DESIGN-CONFLICT-RESOLVER.md for the full analysis.

## Decision
Add a single public command, Resolve-Conflict, that resolves an in-progress
*merge* conflict by letting the user keep their version, the other version, or
both, per file or for all files — using Git's own checkout --ours/--theirs and
union machinery (no new dependency, deterministic, MPL-clean). It is the
sanctioned exception to DR-010: the one command allowed to operate on a
conflicted repo. It does NOT intelligently auto-merge competing edits to the
same line, does NOT depend on a GUI tool on the primary path, and does NOT use
an LLM. A GUI hand-off (git mergetool) may exist only as an opt-in -OpenInTool
escape hatch. Rebase-in-progress is explicitly out of scope and refused, because
the ours/theirs mapping inverts under rebase.

## Source
- docs/DESIGN-CONFLICT-RESOLVER.md
- DR-010 (amended below)
- Private/Get-GEConflictFile.ps1; Public/Save-Work.ps1:333

## Phase
4
```

## DR-010 amendment (ratified — now lives under DR-010 in `DECISIONS_PHASE2.md`)

```
**AMENDED 2026-06-06 (per DR-017, Keith ratified):** Fail-fast remains the law
for Save-Work, Switch-Work, and New-WorkBranch. Resolve-Conflict is the single
sanctioned exception: it is allowed to operate on a repo with unresolved *merge*
conflicts because resolving them is its sole purpose. Rebase/cherry-pick/revert/
bisect in-progress states remain fail-fast for all commands.
```
