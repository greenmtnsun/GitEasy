---
name: dr-author
description: Use when Keith is about to make a non-trivial design choice in any of his PowerShell projects (PesterForge, GitEasy, ClusterValidator, WikiEngine). Provides the Decision Record template, the OPEN/DECIDED/Drift workflow, the per-phase organization (Docs/DECISIONS_PHASE<N>.md), and the rule that DRs are written before code is.
---

> See also: `software-creation` §7 for the canonical DR format and Drift discipline. `phase-gate` for what happens to DRs at phase transitions.

# Decision Record authoring

A Decision Record (DR) captures a non-trivial design choice in plain English so future Keith (and future Claude) can see the intent, the options weighed, and the choice made.

## When to write a DR

Lean toward writing one when:
- The choice has more than one defensible answer
- The choice will be hard or expensive to reverse later
- Future code will depend on the assumption being recorded
- A reader looking at the code in 6 months would ask "why is this like this?"

Skip a DR when:
- The choice is obvious from existing convention
- The change is trivial / stylistic
- The work is exploration / spike (write a DR after the spike if the path stays)

## Before or after code?

Before, except when the choice only becomes clear after a small spike. The DR's value is forcing the design conversation; that conversation matters most when there's still time to take a different option.

## Template

```markdown
# Decision Record NNN — <Title>

## Status
OPEN | DECIDED (YYYY-MM-DD) | DECIDED · drift | OPEN · note

## Question
<one sentence>

## Context
<2–4 paragraphs: what's the situation, what's at stake>

## Options
**Option A — <name>**
- pros / cons
**Option B — <name>**
- pros / cons

## Decision
**<chosen option>.**
Rationale: <plain-English why>

## Blocks / Depends On
- <list>

## Owner
Keith Ramsey

## Phase
<project-defined — e.g. 0, 1, 2 or a feature-name; the phase model is the
project's own bookkeeping, not a global enumeration>
```

## File location

- One file per phase: `Docs/DECISIONS_PHASE<N>.md`
- Big standalone decisions can have their own dedicated file
- Index everything in `Docs/DECISION_REGISTER.md` with a status table + dependency graph

## Status conventions

- `OPEN` — under discussion, code not yet written
- `DECIDED (YYYY-MM-DD)` — chosen; code can proceed
- `DECIDED · drift` — code violates the contract; add a Drift Notice (see software-creation §7) and a recommended fix path
- `OPEN · note` — partial implementation; add an Implementation Note explaining what ships today and what's missing
- `SUPERSEDED` — replaced by a later DR; link to the replacement

## How this skill assists

When Keith says "I'm thinking about X" or "should we Y or Z":
1. Recognize whether the choice qualifies (see "When to write a DR" above)
2. If yes: surface the template, ask for the question + context + options
3. Help structure the options (pros/cons each)
4. Recommend a default if you have one, with one-line reasoning
5. Wait for Keith's pick before code

When Keith asks "what's the status of X" or "did we decide on Y":
- Look up the DR in `Docs/DECISIONS_PHASE<N>.md` or `Docs/DECISION_REGISTER.md`
- Report the status verbatim; don't paraphrase

## What this skill does NOT do

- Doesn't make the decision for Keith — surfaces the question, weighs options, recommends, waits
- Doesn't auto-flip DRs from OPEN to DECIDED without Keith's explicit pick
- Doesn't write code based on an OPEN DR
