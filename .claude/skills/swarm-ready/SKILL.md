---
name: swarm-ready
description: Use when assessing or bringing a project up to the "swarm-ready" bar — the standard that lets multiple agents fan out across a single project fast and safely. Defines the six requirements (tests, work-structure, execution-plan, swarm-runbook, goal-ledger, conformance) plus the read-only audit and batch-gated remediation method. Project-scoped: the discipline lives in this skill, the artifacts live in each repo. Triggers on "is X swarm-ready", "audit X for swarm-readiness", "make X swarm-ready", "can we fan agents at X".
---

> See also: `phase-gate` (phases), `goal-author` (GRs), `dr-author` (DRs), `virtual-uml-architect` (UML-as-contract), `virtual-tester` + PesterForge (tests), `honest-completion` (evidence citation), `verify-claims-on-disk` (trust-but-verify on apply claims), `software-creation` §8 (phase model).

# Swarm-ready project standard

A project is **swarm-ready** when multiple agents can fan out across it — sweeps, parallel sub-agents, "go nuts" — *fast* and *safely*, because the work is decomposed, documented, and verifiable without a human in the loop for every step.

This skill is the reusable **discipline** (the bar). The concrete **artifacts** that satisfy it live inside each project's own repo. Same shape as `phase-gate` (a shared skill) producing `Docs/PHASE.txt` (a per-repo file).

## Scope discipline — read this first

**Products are separate. This skill never crosses a project boundary.** It assesses or remediates exactly one project — or one broken-out subproject — at a time, using only that project's own files. There is no suite-wide swarm-ready document, no cross-project registry, no shared artifact. The only thing shared is *this skill itself*, because a skill is Claude tooling, not a project. If a session ever pulls a swarm-ready artifact from a sibling project, that is a bug — flag it, don't act on it.

## The bar — six requirements

A project is swarm-ready only when all six hold. Each is scored with cited evidence (see §6), never by assertion.

### 1. Tests, hard
- Native framework: **Pester for PowerShell**; the project's own framework otherwise (xUnit for C#, Vitest for TypeScript / Forge).
- Every public function/unit has at least one real test — real-function-pattern, not mock-only theater.
- Tiered REAL / AI-INFERRED / STUB per PesterForge; STUBs disclosed, never silent.
- CI green on every runtime the project claims (e.g. PS 5.1 **and** PS 7).
- "Pester the crap out of it" = the public surface **and** the failure paths, not just the happy path.

### 2. Work structure
- Decisions in `Docs/DECISIONS_PHASE<N>.md` (`dr-author`).
- Goals in `Docs/Goals/GR-NNN-*.md` with a `Docs/GOALS.md` index (`goal-author`).
- Active phase in `Docs/PHASE.txt` (`phase-gate`). Phase model is project-defined.

### 3. Execution plan — how each piece of work gets done
**PowerShell hard rule: every function carries its steps as the contract — no exceptions** (canonical home: CLAUDE.md §5; this section keeps only the checker mechanics). A **checker script enforces it** (reads the code, lists every function, fails the gate on any function missing its blueprint). Claude's judgment is removed from the loop; the script is the judge, and a script can't be talked out of it. (Keith's ruling, 2026-06-03.)

**Where the steps live (settled 2026-06-03):**
- The full steps live as a readable narrative inside each function's **comment-based help (CBH)** — on **every** function, never blank. This is the contract *and* the documentation, and it shows in `Get-Help`. **The CBH is canonical.**
- **Complex functions also get a render-checked activity diagram** that visualizes the same flow. **Tiebreak updated by Keith 2026-08-15 (supersedes the 6/03 "CBH wins" line here — CLAUDE.md §5 is the home):** a properly-authored diagram is presumed right; the Steps may govern when the diagram wasn't done properly or the work originated outside Claude's context; ANY discrepancy = audit which artifact was authored properly, then ask Keith — never self-resolve silently. PlantUML `note` / `'` comment annotations are **encouraged** wherever they make the diagram more accurate.
- A **prompt** may express the steps where a diagram doesn't fit, but the steps must exist in the CBH and be checkable. Reusable, project-agnostic prompts live in this skill's playbook (§ Reusable swarm playbook); project-specific ones live in the project's own `SWARM.md`.
- **Non-PowerShell projects** follow the spirit: every unit carries its step-contract in the native doc-comment form + native-framework tests.

> **The checker** verifies a **non-empty CBH steps section on every function**, plus a **clean-rendering diagram on any function marked complex**. It checks *presence* and *render* — both scriptable. It does **not** try to prove the prose and the picture match semantically; that stays a review check, kept sane by the CBH-canonical rule. "Every function, no exceptions" only means something because the script proves it; Conformance (§6) stays failed until the checker is green.

**A green checker is not the same as a checked project (hardened 2026-10-24, Keith's go).** The judge can only judge the units it can see, and on SpnManager-internal it could not see 134 of them. Five separate blind spots, all fixed and each proved by isolated repro: it scanned paths the project ignores, so the failure count depended on which machine ran it; its C# pattern matched case-insensitively and read a Win32 field named `cbStruct` as a struct declaration; it never looked at a bare `public class` / `struct` / `interface` / `enum`, only at one carrying a modifier; its type characters omitted `?`, so every member returning a nullable type was skipped, which in one fixture meant the `string?` members were invisible while their non-nullable neighbours were checked; and its walk-back for the `///` block stopped at a `//` comment or a `#if`, reporting a blueprint as missing while it sat four lines up. When a count looks suspiciously low or suspiciously stable, suspect the instrument before the code.

### 4. Swarm runbook — `SWARM.md` at the project (or subproject) root
The new per-project artifact. It answers: *how do I safely point many agents at this one repo?* Minimum contents:
- **Parallelizable** — what work can fan out (independent files, per-function tests, per-module docs).
- **Serial-only** — what must NOT be parallelized (shared-state edits, the build, many angles on one file).
- **Isolation** — when agents need a git worktree to avoid clobbering each other.
- **Claim-before-work** — an agent marks a work-item IN-PROGRESS (session id + timestamp) and checks for an existing claim *before* starting, so two agents never do the same work. (This is the handoff-claim/lock mechanism; it lives here.)
- **Verification gates** — the exact non-fakeable checks every agent must clear before claiming done (AST parse, Pester green, PSSA clean, render/drift gate), per `honest-completion`.

### 5. Goal files are the done-ledger
`Docs/GOALS.md` + the GR files ARE the source of truth for what's left — clear, plain-English, understandable cold. A swarm reads them to know what to pick up; a human reads them to know where things stand.

### 6. Conformance — scored, with evidence
The project carries a `Docs/SWARM-READY.md` scorecard rating requirements 1–5 (each MET / PARTIAL / MISSING) with cited evidence for every MET. Same anti-stealth rule as `goal-author`: a requirement is MET only when the body cites the proof (a test run, a file path, a render output). No evidence → not MET.

## Subprojects
A project that contains subprojects carries a **root index** — `PROJECT-MAP.md` (or a README section) — naming each subproject and pointing at its artifacts, so the layout is legible at a glance. A genuinely broken-out subproject is itself swarm-ready and self-contained; the parent index just links to it. The index lives at *that project's* root — never anywhere central.

## The audit (read-only) — scoring a project
When Keith says "audit X for swarm-readiness":
1. Stay inside the one project. Read its `Docs/`, test folder, UML tree, CI config.
2. Score requirements 1–6 MET / PARTIAL / MISSING, citing the file or run that proves each score.
3. For a multi-project sweep, fan one read-only sub-agent **per project** (each blind to the others, each writing a source-project-prefixed entry per [[feedback_handoff_filename_convention]]). Stream each project's score the instant it finishes — never hold a finished score waiting on a slower agent.
4. Hand back a prioritized gap report. **No fixes in the audit pass.**

## Rollout — strategic, surfaced on open, never forced
The standard is **not** retro-applied to every project at once. Rollout is lazy and strategic (Keith's call, 2026-06-03):
- **Surface on open.** When Claude starts working in a project, it checks for that project's scorecard (`Docs/SWARM-READY.md`). Missing or gappy → Claude *mentions* the status and *offers* to remediate, then defers to Keith. The **absence** of a scorecard is itself the signal; nothing is pre-seeded across the fleet. A project Keith doesn't open for months is never touched, and he may decline some indefinitely.
- **Never forced.** Surfacing is an offer, not a gate.
- **Proactive targets = big-but-stable projects** — large enough to benefit, not under heavy active churn where the discipline would disrupt in-flight work. Named 2026-06-03: **ClusterValidator**, **SqlBackupValidation**.
- **Hold the heavily-in-flight projects** — the 4–5 being actively built right now. Applying the standard mid-churn isn't helpful; let them stabilize, and surface-on-open catches them later.

## Remediation — batch-gated, never a blank check
Bringing a project up to the bar edits its code and docs. Per CLAUDE.md §7 and [[feedback_go_needs_explicit_scope]]:
- Work a **prioritized batch** (one project, or one requirement across a few projects), then stop and report.
- Get Keith's explicit go before the next batch. "Start fixing" authorizes the first batch, not an unsupervised sweep of every repo.
- Every fix carries its own verification evidence before it is claimed done.

## Reusable swarm playbook (project-agnostic prompts)
The central, project-agnostic prompts live here; project-specific variants go in each repo's `SWARM.md`. Seeded — filled in as patterns prove out (never fabricated):
- **Audit fan-out** — one read-only agent per project returns a 1–6 scorecard with evidence, prefixed and streamed.
- **Per-function test fan-out** — one agent per untested public function authors a real-pattern Pester test, tiered.
- **UML-step authoring** — one agent per significant code unit drafts the diagram steps as the contract, render-gated.
- **Adversarial verify** — one agent per "it worked" claim tries to refute it against on-disk reality.

## What this skill does NOT do
- Does not cross project boundaries — one project (or subproject) at a time.
- Does not invent test/goal/UML content a project hasn't earned — anti-vibe per `editorial-stance`.
- Does not fix anything during an audit; the audit is read-only.
- Does not remediate beyond the batch Keith authorized.
- Does not declare a project swarm-ready without cited evidence for each requirement.

## Output to Keith
- Per project: a 1–6 scorecard — MET / PARTIAL / MISSING, each with evidence or the specific gap.
- For a sweep: the consolidated, prioritized gap list, streamed as scores arrive.
- Then: "Here's the gap list. Which batch do you want fixed first?"
