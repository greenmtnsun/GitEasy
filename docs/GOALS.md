# GitEasy — Goal Records

Project-scoped goal ledger. One line per goal. Files live in `Docs/Goals/`.

See `~/.claude/skills/goal-author/SKILL.md` for the authoring discipline.

## Index

| ID | Title | Status | Phase | Opened | Closed |
|----|-------|--------|-------|--------|--------|
| [GR-001](Goals/GR-001-two-repo-split.md) | Execute the two-repo public/private split | OPEN | ongoing | 2026-05-23 | |
| [GR-002](Goals/GR-002-github-pr-ref-bpa-purge.md) | Purge BPA-tainted PR refs on origin | OPEN | ongoing | 2026-05-23 | |
| [GR-003](Goals/GR-003-pester-suite-green.md) | Restore Pester suite to green (569/569) | OPEN | ongoing | 2026-05-23 | |
| [GR-004](Goals/GR-004-psscriptanalyzer-punch-list.md) | Resolve PSScriptAnalyzer warnings on PSGallery card | OPEN | ongoing | 2026-05-23 | |

## Lifecycle

- `OPEN` — written, not yet started
- `IN-PROGRESS` — work has started
- `MET` — acceptance criteria all checked **and** evidence cited in the GR body
- `ABANDONED` — explicitly killed; reason in the GR body

A GR can only flip to `MET` when its body cites the tool-call evidence (commit SHA, test run, file path, `/goal` evaluator pass) that proves each acceptance criterion. No stealth completion.
