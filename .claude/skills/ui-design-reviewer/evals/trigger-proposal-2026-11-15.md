# Trigger test for `ui-design-reviewer`, with a proposed description (2026-11-15)

Keith chose "Draft skill triggers only" before his vacation. After reading the result he chose
"Claude applies it" the same day, so `SKILL.md` now carries the proposed description below. The
earlier wording is in git history (commit 9ea537e and before).

## Proposal

Replace the description with the round 2 wording below. It fixed the one query the current
wording handled badly, a design described in words with no file attached, and it triggered on no
near miss.

| Query | Current | Proposed |
|---|---|---|
| "is this error state design ok? ... field border red and a toast" | 1 of 3 runs (fail) | 3 of 3 |
| "the forge macro config panel design, will it work at 300px ..." | 2 of 3 | 3 of 3 |
| "contrast check for the empty-state mockup: #8a94a6 on #f7f8fa ..." | 2 of 3 | 2 of 3 |
| The other 7 should-trigger queries | 3 of 3 each | 3 of 3 each |
| The 10 near misses | 0 of 3 each | 0 of 3 each |

Totals: current 19 of 20 queries right, proposed 20 of 20.

The loop's own pick was the current wording. It chooses by the held-out queries, and both wordings
scored 8 of 8 there, so the tie kept the original. The proposal is Claude's pick, because round 2
also fixed the training failure without adding a false trigger.

**Proposed:**

> Use this skill to critique any UI design or screen behavior someone describes, sketches, mocks up
> or screenshots, from a whole flow down to one error message, validation state, empty or loading
> state, toast or dialog. It covers designs before code exists (mockups, state diagrams, the design
> decision record) and built screens compared against the approved mockups. It is the reviewer for
> the delivery-pipeline UI design review loop (Design phase) and the Verify-phase UI review, for
> Forge/Confluence apps, DetentShell and websites. Use it for questions like "is this design ok?",
> "does this error handling make sense?", "is this accessible?" or "does the build match the
> mockup?", including casual ones that never say "review". It checks states, focus, screen readers,
> contrast, layout, tokens, consistency and wording, and reports findings in the review-loop shape.
> Not for creating a new visual style, writing UI code, drawing diagrams, or standalone WCAG trivia.

**Current:** the `description` line in `..\SKILL.md`.

To apply it, Claude replaces the `description` line in `SKILL.md` on Keith's go.

## How the test ran

- 20 queries: 10 that should use the skill and 10 near misses (`trigger-evals.json`). Keith didn't
  review the set, because he was away.
- Each query ran 3 times in a fresh `claude -p` session on `claude-opus-5-5`, one session at a time.
  Raw results: `trigger-results-2026-11-15.json`.
- The test sessions stayed apart from Keith's setup: subscription login, no user settings, hooks,
  skills or MCP servers, no saved transcripts, and test commands in a scratch folder only.
- Claude copied skill-creator's scripts to the scratchpad and patched the copies; the shared
  scripts stay as they were. Two problems in them are worth knowing:
  - `run_eval.py` reads the `claude -p` output with `select()` on a pipe, which fails on Windows.
    The copy reads it with a thread instead.
  - Parallel workers share one commands folder, so a test session can see other workers' copies of
    the same candidate and count a miss. The runs here used one worker per skill.

## Limits

- The test sessions saw 22 built-in skills, not the ~200 in Keith's sessions, so trigger rates read
  higher than they would for real.
- The review-loop test ran at the same time, so each session also saw that skill's candidate.
  That's realistic, since the two skills live side by side.
