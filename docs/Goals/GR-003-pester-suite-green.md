---
id: GR-003
title: Restore Pester suite to green (569 / 569 passing)
status: OPEN
phase: ongoing
opened: 2026-05-23
closed:
linked-drs: []
linked-plan: n/a
---

# GR-003 — Restore Pester suite to green (569 / 569 passing)

## Why

The 2026-05-23 publish-readiness audit discovered the entire Pester suite is failing — 0 of 569 tests passing on the current commit. Three distinct bugs cause every failure: a Pester 5 scoping bug, legacy `Should Be` syntax left over from Pester 4, and an undefined `Invoke-TestGit` helper. The manifest's release notes claim *"569 tests on Pester 3.4.0, PS 5.1 + PS 7"* — that claim ships verbatim on the PSGallery card and is currently false. Either the tests pass before publish, or the release notes lie. Anti-vibe brand requires the tests to actually pass.

This goal is INDEPENDENT of the URI 404 issue and INDEPENDENT of the repo-split. It blocks PSGallery publish regardless of those.

## Acceptance criteria — autonomous (`/goal` drives these)

- [ ] `$ProjectRoot` / `$ModulePath` / `$ManifestPath` scoping is fixed in all `Tests/*.Tests.ps1` files (move to `BeforeDiscovery` or each `BeforeAll`)
- [ ] All `Should Be` invocations in `Tests/Unit/` are updated to `Should -Be` (dash form, Pester 5 syntax)
- [ ] `Invoke-TestGit` is either defined as a test helper or its two call sites in `GitEasy.AuthCommands.Tests.ps1:139` and `GitEasy.Harvest.Tests.ps1:238` are corrected
- [ ] `Invoke-Pester -Path Tests/ -Output Detailed` reports `Passed: 569 / Failed: 0` on PowerShell 7
- [ ] `Invoke-Pester -Path Tests/ -Output Detailed` reports `Passed: 569 / Failed: 0` on Windows PowerShell 5.1 (run separately; verify both editions because manifest claims compatibility with both)

## Acceptance criteria — human-gated (STOP loop, hand off to Keith)

- None. This is a mechanical fix; no Keith decisions required.

## Non-goals

- Adding new tests. Restore the existing 569 to green; do not expand coverage in this goal.
- Migrating the test suite to Pester 5 idioms beyond what's required to make tests pass (e.g., `Mock` modernization, `BeforeAll`/`AfterAll` lifecycle refactoring). Only fix what's broken.
- Modernizing `Publish-GitEasy.ps1:185`'s legacy Pester 4 invocation style. That's a follow-up; not blocking.
- Fixing PSScriptAnalyzer warnings (tracked separately in GR-004).

## Linked work

- Plans: n/a
- Decisions: n/a
- Phase: ongoing
- Related: 2026-05-23 publish-readiness audit (in-conversation; not committed as a doc)

## Status log

- 2026-05-23 opened OPEN
