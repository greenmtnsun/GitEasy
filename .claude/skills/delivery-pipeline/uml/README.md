# Delivery pipeline review loops: UML

Release pin: **review-loops spec 1.2.1** (`..\review-loops.json`). Reconciled against
`C:\Users\keith\.claude\workflows\delivery-pipeline.js` as edited on 2026-11-15, in the same
commit as these diagrams. When the spec version changes, update every diagram title in the same edit.

Mode: greenfield (2026-11-14). The requirements are the adopted spec; it becomes a Mode A living
corpus now that the code has landed.

## Honest gaps (written first)

This corpus covers one slice of a Workflow-engine script, not a PowerShell module, so most of the
12-slot template does not apply:

- **Use case, deployment, package, component:** one file, run by Keith through the Workflow tool
  inside a Claude Code session. Nothing to show beyond that sentence.
- **Trust boundary:** every agent the script starts runs with the session's own permissions and
  hooks. The script adds no boundary of its own.
- **State (finding lifecycle):** a finding is `open`, `repaired` or `waived`. The JSON spec states
  that more plainly than a state diagram would.
- **Sequence:** the agent calls are the activity steps; a sequence view would repeat diagram 02.
- **Class:** the finding shape is the `finding` block of `review-loops.json` and `FINDING_SCHEMA`
  in the script.
- **The other five phases** (Discovery, Build, Document, Ship-dev, Operate) are single agent calls
  with no control flow and are not drawn.

## Diagrams

| # | File | View | Captures | Does not capture |
|---|---|---|---|---|
| 01 | `01-activity-review-phase.puml` | Activity | The caller's choice of reviews and round cap (`verifyReviewSet()`: the small-item check before Verify), then `reviewPhase()`: pending scope per review (tagged with the pass and cap), cross-review re-runs, the pass cap, a phase stop halting the workflow with its findings | What one review does inside its loop; the wording of the stop record; the test-file pattern |
| 02 | `02-activity-review-loop.puml` | Activity | `reviewLoop()`: fresh reviewer each round, the exit rule, the stop rules, the carried exit at the cap (3 or 5), Keith's rulings, repair, re-run, and that a stop on an escalation leaves that round's repairs untested and unreviewed | Prompt wording; the finding fields |

## Rendering

Source only; no rendered images are committed. One-off check, the same call `uml-render-check` makes:

```
java -jar C:\Users\keith\.claude\plantuml.jar -failfast2 -tsvg -o <scratch folder> <file>.puml
```

## Contract rule

The spec, these diagrams, the `Steps:` comments in the script and the code must agree. On any
mismatch, audit which one was authored properly and bring it to Keith (CLAUDE.md section 5).
The script cannot read files, so `REVIEWS` and the three limits at the top of its review-loop block
are a hand copy of `review-loops.json`: change both together.
