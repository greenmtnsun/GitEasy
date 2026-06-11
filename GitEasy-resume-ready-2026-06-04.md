# GitEasy — Resume-Ready (prepped 2026-06-04)

Peer note to the next GitEasy Claude. Everything below traces to a file I read; unverified items are in **Honest gaps**, not invented.

**Current state:**
- **Version 1.5.5**, single unified module, 21 exported commands + 3 aliases (`GitEasy.psd1` lines 3, 12-41). Phase 4 — Maintenance, ACTIVE (`docs/PHASE.txt`).
- **1.5.5 is committed and on origin/main but NOT yet published to PSGallery.** Local manifest = 1.5.5; `Find-Module GitEasy` returns **1.5.4** (verified live 2026-06-04). The version gap is the headline. The three blockers from `PUBLISH-STATUS-2026-05-31.md` are now resolved: version bumped to 1.5.5, `GitEasy-internal\tools\Publish-GitEasy.ps1` is committed clean (internal HEAD `296dde5`), PSSA gate is wired into CI.
- **Working tree clean, in sync with origin/main** (`git status -sb`). Head commits: `6d10e04` (plantuml wrapper + render gate), `e314b3c` (12 UML diagrams, GR-002), `ff3221f` (Steps: blueprints on all 78 functions, swarm-ready MET).
- **Goals** (`docs/GOALS.md`): GR-002 (UML 12/12) DONE, GR-003 (swarm-ready) DONE, **GR-001 (Phase-4 maintenance baseline) OPEN** — it is the standing regime, never closes.
- **CI** = `.github/workflows/pester.yml`: two jobs (Windows PowerShell 5.1 + PowerShell 7), each running `tools\Run-GitEasyPester.ps1 -ThisEditionOnly`, the jargon audit, and a PSSA Error-severity gate. (Note: the old `ci.yml` was removed in `c30927c`; `pester.yml` is the only workflow.)
- **0 `# STUB:` / `STATUS:` markers** in any `.ps1` (grep, whole repo). All PowerShell parses clean (parse-sweep 2026-06-04, "All PowerShell parses clean").
- **Tooling split:** public repo `GitEasy\tools\` holds `Run-GitEasyPester.ps1`, `Audit-PublicJargon.ps1`, builders, `Test-UmlVersionDrift.ps1`. The **publish script lives only in the sibling private repo** `GitEasy-internal\tools\Publish-GitEasy.ps1` — by design, so it never ships in the `.nupkg`.

## Next step (when you reopen this)

**Publish 1.5.5 to PowerShell Gallery.** This is outward-facing/irreversible, so confirm with Keith before the real `-Publish` (per CLAUDE.md §7). Sequence:

1. Dry-run first (stages, validates manifest, runs Pester, network-checks URIs — no publish). Run from the **GitEasy-internal repo root** `C:\Sysadmin\Scripts\GitEasy-internal`:
   ```powershell
   .\tools\Publish-GitEasy.ps1
   ```
   (Default `-ProjectRoot` resolves to the sibling `GitEasy\` public repo.)
2. Confirm the dry-run reports 1.5.5 staged, function count = 21, Pester all-green, URIs reachable.
3. **Ask Keith to authorize**, then real publish (he holds the key — this is the live outward write):
   ```powershell
   .\tools\Publish-GitEasy.ps1 -Publish -NuGetApiKey (Read-Host -AsSecureString -Prompt 'PSGallery API key')
   ```

## Success check

`Find-Module GitEasy` returns **1.5.5** (today it returns 1.5.4). The Gallery page shows the 1.5.5 ReleaseNotes block (PSGallery tag corrections + GitHub Actions CI). CI on `main` stays green on both PS legs.

## Known traps

- **Pester 3, not 5.** Test stack is pinned to Pester 3.x (DR-009). `Run-GitEasyPester.ps1` filters `Version.Major -lt 4` because a co-installed Pester 5 silently mis-runs Pester-3 syntax as 0/N pass (CHANGELOG 1.3.0). Don't "upgrade" the runner.
- **`Should Throw` / `Should Not Throw` are broken** under PS 7 and elevated interactive hosts. Tests use `try/catch` + `Should (Not )BeNullOrEmpty` instead (CHANGELOG 1.0.0 / 1.3.0). Match that pattern in any new test.
- **Never `Publish-Module` against the repo root** — it would pull in `Tests/`, `tools/`, `.git/`, internal docs. The enumerate-then-include staging in `Publish-GitEasy.ps1` is the only sanctioned path (script `.DESCRIPTION`).
- **`.psd1` here-string is a deliberate exemption** (DR-011). The no-here-strings rule applies to `.ps1`/`.psm1` only; inline `ReleaseNotes` is the natural shape. Don't "fix" it.
- **Write-Host is project convention** (structured output to host). `PSAvoidUsingWriteHost` is disabled in `PSScriptAnalyzerSettings.psd1` (GR-004 confirmed 0 warnings). CI's PSSA gate uses that settings file — don't bypass it.
- **Credential-surface is hard-won.** F-01..F-06 closed the regex-URL-parsing credential leak across six sibling sites (`docs/SECURITY-FINDINGS-2026-05-17.md` / `-05-20.md`). The triad is `Format-GESafeUrl` + `Format-GESafeLogLine` + `Test-GERemoteUrlSafe`. Any new code that touches a remote URL on a log/output/error path **must** route through `Format-GESafeUrl` (DR-012/DR-013). The root cause recurred once after the first sweep — fan out for siblings before declaring any URL-parse fix closed.
- **Plain-English public surface is gated in CI** (`Audit-PublicJargon.ps1`). A `-Staged` switch was caught as HARD-jargon in 1.5.0 and renamed `-NextSave`. Keep Git terms off command names and returned-object fields.
- **Test-count figures in old CHANGELOG prose were overstated** (1.0.0 and 1.5.0); the [Unreleased] note documents the audit. Trust the empirical runner output, not narrative counts.

## Later, separate session (design-first, not a tack-on)

**AI-merge-tutor** is the queued next big feature (memory: `project_giteasy_ai_merge_tutor`). It is NOT started in this repo — no `merge-tutor`/`AI-merge` references exist in source (grep, 2026-06-04). Treat it as design-first: author the design-proposal UML and a DR before any code, and there is one OPEN fork that is **Keith's call — confirm before building**. Do not bolt it onto a maintenance release.

## Honest gaps

- I did not run the full Pester suite this session (the parse-sweep passed; CI is the authority on green). Confirm CI is green on `main` before publishing.
- Empirical 1.5.5 test count not re-counted here. CHANGELOG's last reconciled figure is 569 at 1.5.3; post-1.5.3 commits added swarm-ready/UML tooling tests (e.g. internal commit `3a1af71` cites "554/554" for the internal repo's own suite — a *different* suite from the public 569). Don't quote a single combined number without re-running.
- The `Wiki/`, `site/`, `docs/` wiki-generation surface (`Update-GitEasyCommandWiki.ps1` in the internal repo) was not audited for drift this session.
- Whether the 1.5.5 commit was tagged on GitHub (`git tag`) was not verified — check before/after publish so the Gallery release and the repo tag agree.
