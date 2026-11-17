---
name: release-qa-passes
description: Use at release/milestone cadence in Keith's repos — cutting a release, closing a milestone, pre-release prep, or building the test plan for a new feature. Encodes the three release QA passes adopted 2026-08-07 (A test-suite audit per milestone, B regression pack per release cut, C SFDIPOT feature attack per new feature) plus D, an unexpected-behaviour triage scaffold that is a bug-intake template, NOT a pipeline step. Judgment passes that produce work items, not pass/fail gates — never run per-commit. Rollout is currently a pilot on GitEasy + DetentShell. Triggers on "cut a release", "release prep", "is this release ready", "audit the test suite", "regression pack", "SFDIPOT", "milestone complete", "attack this feature". Pairs with delivery-pipeline (these live in its Verify phase) and verify-claims-on-disk (the discipline rules below).
---

> See also: `delivery-pipeline` (these passes are Verify-phase steps and log to its `docs/PIPELINE.md` ledger), `honest-completion` + `verify-claims-on-disk` (the claim discipline the rules below apply to QA findings).

# Release QA passes

Origin and authority: Keith pointed Meta-Claude at a QA prompt library (Zero Defect Academy playlist), four of fourteen prompts survived trial on real suite material, and Keith approved adoption 2026-08-07. Full trial evidence and directive chain: `C:\Users\keith\.claude\plans\Meta-to-dotclaude-qa-prompt-ci-integration-2026-08-07.md`. Do not re-derive what that report already settled.

These are **release-path passes, not per-commit gates.** They are judgment passes that produce work items — there is no green/red answer, so running them per-commit adds cost and noise. SUITE-PR-GATE.md (canonical home: `C:\Users\keith\.claude\cross-project-artifacts\SUITE-PR-GATE.md`, fixed 2026-08-15) is the per-PR mechanical gate and is deliberately NOT where these live.

## Standing discipline — applies to every pass, every run

Proven necessary in trial (a casual single-file run false-alarmed; the disciplined run produced six real findings and zero fabricated ones):

1. **Whole-repo context.** Load the full source and every test suite before claiming a gap. Never run a pass on one pasted file.
2. **Verify on disk before reporting.** Every claimed gap/duplicate/weak assertion gets checked against the actual files (e.g., search every test file before calling a behavior untested).
3. **Findings cite file:line** in both source and tests.

## Pass A — Test-suite audit (per milestone, or pre-release)

> Audit the test coverage for [FUNCTION/FEATURE] across the whole repo (all test
> files, not one). Find: 1) coverage gaps — behavior in the source with no exercising
> test anywhere; 2) duplicate or near-duplicate tests; 3) weak assertions — tests
> that would still pass if the behavior regressed; 4) obsolete tests. For each
> finding: file:line in source and tests, why it matters, and the specific test to
> add/merge/strengthen. Verify each gap claim by searching every test file before
> reporting it.

## Pass B — Regression pack from a change list (every release cut)

> We are releasing [PROJECT] v[VERSION]. Changes since the last shipped build:
> [commits/changes]. Identify at-risk areas and build a targeted regression pack.
> Format: Risk Area · Why this change puts it at risk · Tests to run (name the
> automated suites that already cover it; mark what needs a manual pass) · Priority.
> Do not pad with generic smoke items unconnected to the change list.

## Pass C — SFDIPOT feature attack (per new feature, or pre-release on the headline feature)

> I am testing [FEATURE]. [1-2 sentence description]. Apply SFDIPOT — 2 attack ideas
> per category: Structure, Function, Data, Interfaces, Platform, Operations, Time.
> Ground each idea in this codebase's actual architecture (name the components), not
> generic advice.

## Template D — Unexpected-behaviour triage (bug intake only — never a pipeline step)

Use when filing or picking up an anomaly report, at any time, not on a cadence:

> App: [APP]. Feature: [FEATURE]. Observed: [exactly what happened, including what
> DIFFERS from the working case]. 1) Bug or expected — and in whose code (product,
> harness, environment)? 2) Most likely cause, as a testable hypothesis. 3) Minimal
> next test that discriminates between the top two hypotheses.

The load-bearing question is "in whose code — product, harness, environment?"

## Evidence rows — every run gets logged (Keith, 2026-08-07)

Each run adds a row to the repo's `docs/PIPELINE.md` under Verify, using the ledger's existing three-column schema — Status, Evidence, Date. Evidence names the pass, the target, the findings count, and the path to the findings file. Example:

```
| Done | Release QA pass A (test-suite audit) on Save-Work — 6 findings, see Docs/qa/A-save-work-2026-08-07.md | 2026-08-07 |
```

Per the ledger rule in `delivery-pipeline`: the row is written in the same pass as the run, not as later bookkeeping. A "Verify done" claim at release time should be able to cite these rows.

## Rollout scope (current)

Pilot: **GitEasy and DetentShell** first — the repos the trial evidence came from. Suite-wide extension is Keith's call after a full release cycle on the pilots proves the cost and cadence. Decision: Keith via AskUserQuestion, 2026-08-07, this workspace.

## Cost note

A and C are the expensive passes — a real audit reads the source and every suite. Per-milestone cadence keeps them affordable; per-commit would not be. If a repo's cadence makes a pass feel too expensive, surface the tradeoff to Keith; don't silently skip or thin the discipline rules.
