---
name: review-loop
description: How to run a review that repeats until no finding stays open (code review, security review, UI design review, UI review, or any reviewer-and-builder cycle) in any orchestration, such as the delivery-pipeline workflow, a review walked by hand in conversation, a release QA pass, or a custom Workflow script. Use it whenever work must be "reviewed until clean", whenever a review round finds problems that need fixing and re-checking, when a review loop stops and asks Keith, when resuming a stopped run with Keith's rulings (keithRulings), when deciding what happens to findings at the round cap, or when writing waivers and carried findings to a project's PIPELINE.md. Use it even when the request only says "review this and fix what you find", since that's a review loop.
---

# Review loop

A review loop is one review that repeats until no finding is open. A fresh reviewer finds problems,
the builder fixes them or proposes a waiver, tests run again, and a new reviewer checks the result.
Keith adopted it for the official delivery process on 2026-11-14 and amended it on 2026-11-15.

## Where the rules live

There is one copy of the rules. This skill points at it and doesn't restate the numbers.

| What | Where |
|---|---|
| The rules (spec 1.2.x) | `C:\Users\keith\.claude\skills\delivery-pipeline\review-loops.json` |
| The control flow | `C:\Users\keith\.claude\skills\delivery-pipeline\uml\01-activity-review-phase.puml` and `02-activity-review-loop.puml` |
| The running code | `C:\Users\keith\.claude\workflows\delivery-pipeline.js` (`reviewPhase`, `reviewLoop`, `haltForKeith`) |
| The tests | `C:\Users\keith\.claude\skills\delivery-pipeline\tests\run-scenarios.js` |
| How to use it, for people | `guide\review-loops-guide.html` and `guide\review-loops-guide.pdf` beside this file |

Read `review-loops.json` before running a loop by hand. It's short, and it holds the round caps, the
size rule, the waiver limits and the stop rules.

## The loop

0. Size the work first, by `loop.size` in the spec. A small item gets one reviewer per round who
   applies both the code and the security checks, and a lower round cap. Anything bigger gets
   separate code and security loops and the normal cap. Keith set this on 2026-11-15 after a loop on
   a 40-line function ran 96 minutes with two reviewers a round.
1. A fresh reviewer agent reviews the work. It never built or repaired it. From round 2 it reports
   on every earlier finding by id before it looks for new ones.
2. No open findings: the loop is clean.
3. Any of these stops the loop and goes to Keith:
   - a diagram, `Steps:` or code mismatch (CLAUDE.md section 5);
   - a finding still open after 2 repair rounds (CLAUDE.md section 18);
   - a medium or worse finding still open at the round cap;
   - a builder escalation, or a waiver proposed for a critical or high finding. This stop comes
     straight after the repair round, so that round's repairs aren't re-tested or reviewed. Keith
     kept it that way on 2026-11-15, because a resume with his ruling reruns that round anyway.
4. At the round cap with only low findings open, the loop ends as carried: those findings go to the
   ledger as open items for Keith, and the work goes on.
5. Otherwise the builder repairs each finding or proposes a waiver with a reason. Tests and static
   analysis run again. Every other review in the same phase looks again at the files that changed.

## Which reviewer

| Review | Phase | Reviewer |
|---|---|---|
| UI design | Design, when there is a UI | the `ui-design-reviewer` skill |
| Code | Verify | the `code-review` skill at level high (never max or ultra unless Keith asks) |
| Security | Verify | the `virtual-security-reviewer` skill |
| Code and security, small item | Verify | one agent applying both of the above |
| UI | Verify, when there is a UI | the `ui-design-reviewer` skill, "Built screens" section |

## Three ways to run it

### In the delivery-pipeline workflow

The workflow runs every loop for you. Pass `hasUi` so the UI loops run when they should, and
`ledgerPath` when one repo holds more than one product. Keep the launch result's run id and script
path. The delivery-pipeline skill has the full argument list.

### By hand, in conversation

1. Spawn each review round as a new subagent (Agent tool). Don't reuse an agent across rounds.
   Brief it fully, because the brief is all it knows:
   - the review's checks and the finding shape from `review-loops.json`;
   - the house bars the work must meet. For PowerShell that's `function-design`,
     `software-creation` and `compliance-checklist`, plus the CLAUDE.md section 5 rule that every
     function carries a `Steps:` blueprint, test helpers included. In the 2026-11-15 skill test,
     briefs that left these out meant no round checked the test helpers. Tell the reviewer to apply
     each bar only where its own skill says it applies: `software-creation`'s never-throw,
     structured-result rule covers module functions, not a standalone script. In round 2 of the
     test a reviewer held a 46-line script to it, and the builder had to escalate;
   - the one folder it may write probe scripts and test files to. A reviewer using `code-review` may
     fork, and in the same test a fork wrote probes outside the run's folder. Tell the reviewer to
     pass the folder on to any fork;
   - that it reports a mismatch between a diagram, a `Steps:` blueprint and the code as needsKeith.
     Nobody fixes one by rewriting the blueprint;
   - that it reads the repo's `REVIEW.md` from the default branch before it reads the code (the
     section below), and says in its notes when there is none.
2. Act as the builder yourself: repair, or propose a waiver with a written reason.
3. Re-run the tests and static analysis for real, and record exact counts.
4. Pass the next reviewer the earlier findings and your repairs.
5. Apply the stop rules and the cap exactly as written. A loop walked by hand follows the same rules
   as the workflow.
6. End by naming the loop's status (clean, carried or stopped), the round it ended on, and why.

### Inside another Workflow script

The loop code lives in `delivery-pipeline.js` only. A new Workflow script that needs it copies
`reviewLoop`, `reviewPhase`, `loopResult`, `haltForKeith`, the four review schemas, `REVIEWS` and
the limits, and proves its copy against `tests\run-scenarios.js` before running it. No standalone
review-loop workflow exists yet.

## When a loop stops

The stop record lists each finding's location, evidence and suggested repair, the open items the
phase agents left for Keith, and any findings carried so far. When the builder's escalation or
waiver stopped it, the record also says that round's repairs weren't re-tested or reviewed. A loop
walked by hand says the same when it stops that way.

1. Take it to Keith in the question window: one finding per question, with a recommended answer.
2. Write his answer as a ruling: `{ id: 'code-3', ruling: 'Keith's words' }`.
3. Resume the run with the same args plus `keithRulings`:

   ```
   Workflow({ scriptPath: '<from the launch result>', resumeFromRunId: '<run id>',
     args: { ...the same args..., keithRulings: [{ id: 'code-3', ruling: '...' }] } })
   ```

   Change nothing else in the args. A changed description reruns every agent from Discovery, while
   rulings reach only the repair round that carries them out, so the earlier agents replay from cache.
4. One repair round carries out each ruling, then one more fresh review checks it, past the cap if
   need be. The loop carries out each ruling once. If its finding is still open after that, the normal rules
   apply again.
5. A ruling on a finding that stopped at the 2-repair rule lands on that finding's first repair round
   in the replay, in place of the original repair. Everything from that round on runs live, and the
   finding gets one more ordinary repair before the 2-repair rule can stop the loop again
   (`rulings.afterTwoRepairStop` in the spec).

Never resolve a stop yourself, even when the answer looks obvious.

## The repo's review focus: REVIEW.md

A repo may keep a `REVIEW.md` at its root: what a reviewer looks at first, rules from past misses
with the miss named, and what not to flag. Keith adopted it on 2026-11-17 from the Claude Code team's
practice, where tuning one reviewer beats stacking several. The template is
`C:\Users\keith\.claude\skills\review-loop\TEMPLATE-REVIEW.md`.

Two rules make it a gate rather than a note:

- **The reviewer reads it from the default branch, never from the working tree or the branch under
  review.** `git show origin/HEAD:REVIEW.md`, then `main`, then `master` if that fails. A change
  cannot edit its own checks. Edits to `REVIEW.md` go in their own commit on the default branch.
- **A rule earns a line when the miss recurred in at least two changes and a diff can show it**,
  the same bar as the pattern library (`PATTERNS.md`). A review finding that would have been caught
  by a rule, and was not, is the signal to add one.

When there is no `REVIEW.md` on the default branch, the reviewer says so in its notes and reviews
against the house bars alone. The workflow's reviewer prompt carries this instruction from spec
1.2.2 on; a loop walked by hand puts it in the brief.

## The ledger

Waivers and carried findings go in the project's `docs\PIPELINE.md`, or the file named by
`ledgerPath`. Nothing else goes there: not a stop, a ruling or a pending resume. Those stay in the
stop record and the run's result. In round 2 of the skill test a run wrote a ledger row for a halt. In WikiEngine, WikiMint's ledger is `WikiMint\Docs\PIPELINE.md`. The root ledger there
belongs to the Insights generator.

## What makes a run go well

These come from the WikiMint trial report of 2026-11-14.

- Pick one small item: one function, one screen, a few files.
- Settle uncommitted files first, or let the run record them (`treeAtStart`) and leave them out of
  the commit.
- Name the stack and the way tests run in the description. Put the deploy rule there too.
- Expect time. Each review or repair round took 3 to 16 minutes, and five UI design rounds plus
  Discovery and Design took 1 hour 52 minutes. The small-item rule in spec 1.2.0 cuts the Verify
  loops for one short file.
- Commit afterwards with plain git and an explicit file list (`#giteasy-ok`). GitEasy `save_work`
  skips the repo's gates (BUG-031).
- Don't edit `delivery-pipeline.js` while a run is going. The run keeps the copy it launched with.

## Changing the rules

The rules are Keith's. A change goes into `review-loops.json` (with a version bump and a `changes`
entry), the `REVIEWS` block and limits in `delivery-pipeline.js`, the diagram titles and the tests,
in one commit. Then run:

```
node C:\Users\keith\.claude\skills\delivery-pipeline\tests\run-scenarios.js C:\Users\keith\.claude\workflows\delivery-pipeline.js
```

Every scenario has to pass.
