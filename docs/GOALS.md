# GitEasy — Goal Records

Project-scoped goal ledger. One line per goal. Files live in `Docs/Goals/`.

See `~/.claude/skills/goal-author/SKILL.md` for the authoring discipline.

## Index

| ID | Title | Status | Phase | Opened | Closed |
|----|-------|--------|-------|--------|--------|
| _no goals yet_ | | | | | |

## Lifecycle

- `OPEN` — written, not yet started
- `IN-PROGRESS` — work has started
- `MET` — acceptance criteria all checked **and** evidence cited in the GR body
- `ABANDONED` — explicitly killed; reason in the GR body

A GR can only flip to `MET` when its body cites the tool-call evidence (commit SHA, test run, file path, `/goal` evaluator pass) that proves each acceptance criterion. No stealth completion.
