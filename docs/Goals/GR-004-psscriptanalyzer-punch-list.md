---
id: GR-004
title: Resolve PSScriptAnalyzer warnings that surface on the PSGallery card
status: OPEN
phase: ongoing
opened: 2026-05-23
closed:
linked-drs: []
linked-plan: n/a
---

# GR-004 — Resolve PSScriptAnalyzer warnings that surface on the PSGallery card

## Why

The 2026-05-23 publish-readiness audit ran PSScriptAnalyzer against the module surface (excluding `PSAvoidUsingWriteHost` which is project convention). Result: 49 warnings + 20 informational. Errors: 0. PSGallery shows analyzer warnings on the public module page; evaluators (technical buyers, security-conscious sysadmins) check that page before installing. Zero errors is the minimum bar; lowering the warning count is a trust signal.

Two warnings from the audit are already resolved (singular-noun suppression via attribute + alias wiring on three functions; `$args` rename in Show-Releases.ps1 — both landed in commit 5523c2d). This goal handles the remainder.

## Acceptance criteria — autonomous (`/goal` drives these)

- [ ] `Remove-GEOldLog.ps1` adds `[CmdletBinding(SupportsShouldProcess)]` and a `$PSCmdlet.ShouldProcess(...)` guard (or a SuppressMessage with documented rationale, per Keith's decision)
- [ ] `Start-GELogSession.ps1` resolves PSUseShouldProcessForStateChangingFunctions the same way
- [ ] `Update-GitEasyPrivateWiki.ps1:New-PrivateWikiPage` resolves PSUseShouldProcessForStateChangingFunctions the same way
- [ ] The 11 module files missing UTF-8 BOM are re-saved with BOM: `Convert-GERemoteToSsh.ps1`, `Format-GESafeLogLine.ps1`, `Format-GESafeUrl.ps1`, `Reset-Login.ps1`, plus 7 others identified by the analyzer
- [ ] `Reset-Login.ps1:120` empty catch block gets a `Write-Verbose` justification or rule suppression with rationale
- [ ] Public-function `[OutputType()]` decision: either add `[OutputType()]` attributes to all 21 public functions OR suppress with documented rationale per Keith's policy decision
- [ ] Final `Invoke-ScriptAnalyzer -Path . -Recurse -ExcludeRule PSAvoidUsingWriteHost` reports zero Warnings on shipping module code (Tests/ warnings excluded — tests don't ship)

## Acceptance criteria — human-gated (STOP loop, hand off to Keith)

- [ ] Keith decides ShouldProcess policy on the three flagged functions: implement, suppress, or defer (surfaced via UI)
- [ ] Keith decides `[OutputType()]` policy: add attributes to all 21 public functions, suppress the rule, or defer (surfaced via UI)
- [ ] Keith decides BOM policy: re-save files with BOM (recommended for PS 5.1 non-en-US locale safety), or accept the warnings (surfaced via UI)

## Non-goals

- Restructuring the module beyond what each warning requires. No refactors for refactor's sake.
- Adding `[OutputType()]` if Keith decides to suppress — these are informational anyway.
- Suppressing Tests/ warnings. Tests don't ship to PSGallery; their analyzer count doesn't appear on the card.
- Singular-noun warnings on `Get-Updates` / `Show-Releases` / `Undo-Changes` / `Get-GEConflictFiles`. Already resolved in commit 5523c2d (suppressed with rationale + singular aliases exported).

## Linked work

- Plans: n/a
- Decisions: [[DR-002-pssa-policy]] (to be written after Keith's policy decisions)
- Phase: ongoing
- Related: 2026-05-23 publish-readiness audit

## Status log

- 2026-05-23 opened OPEN
