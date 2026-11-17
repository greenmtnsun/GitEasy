# Trigger test for `review-loop` (2026-11-15)

Keith chose "Draft skill triggers only" before his vacation. Claude applied nothing.

## Keep the current description

The current description got all 20 queries right, 3 runs each, so the loop stopped after its first
round with no change to propose.

- The 10 should-trigger queries triggered 3 of 3 runs each, including a hand-walked loop on a small
  function, a resume after a 2-repair stop, a waiver question, and a release re-review.
- The 10 near misses triggered 0 of 3 each, including a one-pass review that only lists findings, a
  report-only security review, a test-suite audit, and a production-deploy question.

Every query was all or nothing. That fits a description that works, but it also means the set may be
too easy to tell a good description from a weak one. A harder set would add two kinds of near miss.
One asks for a fix with no re-review. The other means a review loop in another sense, such as a PR
review cycle with a human reviewer.

## How the test ran

It ran the same way as the ui-design-reviewer test, in the same session. See
`..\..\ui-design-reviewer\evals\trigger-proposal-2026-11-15.md`, "How the test ran" and "Limits".
Queries: `trigger-evals.json`. Raw results: `trigger-results-2026-11-15.json`.
