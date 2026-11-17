---
name: phase-gate
description: Use at phase transitions (Phase N complete → N+1) in any of Keith's PowerShell projects. Walks through phase reconciliation (every DR flips to DECIDED with date, or stays OPEN with Implementation Note), updates Docs/PHASE.txt, and verifies the next phase's blocking decisions are resolved before code starts.
---

> See also: `software-creation` §8 for the phase model. `dr-author` for DR mechanics.

# Phase-gate workflow

Phases are the project's heartbeat: each one has explicit entry and exit criteria. A phase transition is the moment to clean up loose ends from the closing phase and verify readiness for the next.

## Phase model is project-defined

The phase model — count, numbering, naming, scope of each — is project-defined.
This skill walks the *mechanic* (reconcile DRs at transition, update
`Docs/PHASE.txt`, verify next-phase entry criteria) regardless of how phases
are labeled. Triggers fire on "Phase X done" / "ready for Phase Y" without
prescribing what X and Y mean. Project examples observed in the suite:
ModuleWorkshop (Phases 1, 2), DBCCProject (Phase 0 hardening), PesterForge
(Phases 1–3 plus a DR-26 coverage audit outside the numbered ladder),
PhotoOrganizer (Phases 0–3 with 2.0/2.1/3.0/3.1/3.2 sub-phases).

## When this skill triggers

Keith says one of:
- "Phase N is done"
- "Ready to move to Phase N+1"
- "Where do we stand on Phase N"
- "Closing out Phase N"
- "Start Phase N+1"

## What this skill does at trigger

### 1. Reconcile every DR for the closing phase

For each DR in `Docs/DECISIONS_PHASE<N>.md`:
- If the code matches the decision → flip status to `DECIDED (YYYY-MM-DD)` with today's date
- If the code drifts from the decision → keep status, add a **Drift Notice** (see software-creation §7) with file:line and a recommended fix path
- If the DR is partially implemented → keep status `OPEN · note`, add an **Implementation Note** with what works, what doesn't, what would close the gap
- If the DR is no longer relevant → mark `SUPERSEDED` and link the replacing DR (or note "scope dropped")

### 2. Update `Docs/PHASE.txt`

Single line, current phase number only:

```
2
```

This file is the source of truth for which phase is active. (Correction 2026-08-15: the global CLAUDE.md does NOT reference PHASE.txt — §13 references `Docs/PIPELINE.md`; only per-project docs may cite PHASE.txt.) Future automation reads it.

### 3. Verify next phase entry criteria

Read `Docs/DECISIONS_PHASE<N+1>.md` (create if it doesn't exist):
- List every DR scheduled for Phase N+1 with `Blocks` references to the next phase
- Confirm each is either DECIDED or OPEN-with-note
- If any are unresolved with no note → flag as a blocker; don't start Phase N+1 code

### 4. Optional: Keith runs `/code-review ultra`

For phases that ship visible work, `/code-review ultra` against the closing phase's branch is a good final check before declaring the phase complete. (`/ultrareview` is the deprecated alias for the same command.) It is user-triggered and billed — **Keith runs it himself; a session cannot launch it.** Keith decides whether to run it.

## What this skill does NOT do

- Doesn't write code
- Doesn't make decisions for Keith — surfaces what needs decision
- Doesn't auto-flip DRs to DECIDED without verifying code matches the decision
- Doesn't update `Docs/PHASE.txt` until reconciliation is complete

## Output to Keith

A reconciliation report:
- DRs flipped to DECIDED: <list>
- DRs with new Drift Notices: <list with file:line>
- DRs with new Implementation Notes: <list>
- DRs marked SUPERSEDED: <list>
- New blockers for Phase N+1: <list>
- `Docs/PHASE.txt` updated: yes/no, new value

Then ask: "Phase N closed. Start Phase N+1, or pause?"
