---
id: GR-002
title: Purge BPA-tainted PR refs on origin (GitHub Support ticket)
status: OPEN
phase: ongoing
opened: 2026-05-23
closed:
linked-drs: []
linked-plan: n/a
---

# GR-002 — Purge BPA-tainted PR refs on origin (GitHub Support ticket)

## Why

The 2026-05-23 git-history audit confirmed: `main` is clean, but `refs/pull/1/head` (`f747164`) and `refs/pull/2/head` (`a3b4476`) on origin still point at pre-orphan-rewrite commits containing literal "BPA" references in commit messages and file diffs. Anyone who fetches all remote refs, or guesses the URL `https://github.com/greenmtnsun/GitEasy/pull/1/files`, will see employer-name leakage. The nuclear orphan-branch rewrite cannot purge these refs locally; only GitHub Support can. This goal is the only blocker (besides GR-001) before flipping the repo public.

## Acceptance criteria — autonomous (`/goal` drives these)

- [ ] `git ls-remote origin` from a fresh clone shows only `refs/heads/main` and `refs/tags/v1.5.3` — no `refs/pull/*/head` entries containing the tainted SHAs
- [ ] A re-run of the BPA scrub audit returns CLEAN verdict (working tree + local history + remote refs all green)

## Acceptance criteria — human-gated (STOP loop, hand off to Keith)

- [ ] Keith files a GitHub Support ticket at `https://support.github.com/contact` requesting purge of `refs/pull/1/head` and `refs/pull/2/head` for `greenmtnsun/GitEasy` (note: ticket-filing requires Keith's account; we cannot file on his behalf)
- [ ] Keith confirms ticket closure (GitHub Support typically responds within 1-3 business days)

## Non-goals

- Local `git gc` / reflog expiration. The local unreachable objects are cosmetic and never push automatically.
- Closing the PRs through the UI. That doesn't remove the refs; only Support intervention does.
- Force-pushing or repository deletion. Both are heavier hammers than needed.

## Linked work

- Plans: n/a
- Decisions: n/a
- Phase: ongoing
- Related: `SECURITY-FINDINGS-2026-05-20.md` (the broader sibling-sweep that found these)

## Status log

- 2026-05-23 opened OPEN
