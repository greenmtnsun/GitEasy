# GR-001: Phase 4 maintenance baseline

**Status:** OPEN
**Phase:** 4
**Source:** docs/PHASE.txt line 28

## What done looks like

Phase 4 does not close — it is the standing maintenance regime until a new phase opens.
A GR-001 check passes when:

- No public-surface jargon regressions (plain-English rule, DR-001).
- CI stays green on PS 5.1 and PS 7 for every release.
- Each release increments the version in `GitEasy.psd1` and appends a CHANGELOG entry.
- Structured result returned on every public command path (DR-005).

## Why

GitEasy shipped v1.5.x. Phase 4 absorbs bug fixes and named additions without reopening earlier design phases.
