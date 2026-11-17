---
name: goal-author
description: Use when Keith wants to author, update, or drive toward a Goal Record (GR) in any of his projects. A GR is a project-scoped, persistent ledger entry — what we're trying to achieve, why, what counts as done, and the tool-call evidence that proves it. Mirrors `dr-author`'s discipline: written before work, lifecycle-tracked, anti-stealth-completion. Bridges to the shipped Claude Code `/goal` command by rendering acceptance criteria into a verifiable condition string. Pairs with `honest-completion` (the same evidence-citation rule applies to flipping a GR to MET) and `dr-author` (a goal often blocks on or motivates one or more DRs).
---

> See also: `dr-author` for decisions that goals depend on. `honest-completion` for the evidence-citation rule when flipping MET. `phase-gate` for what happens to in-flight goals at phase transitions.

# Goal Record authoring

A Goal Record (GR) captures an intended outcome for a project in plain English so future Keith (and future Claude) can see the target, the acceptance bar, and the evidence that the bar was cleared.

A GR is **not** a decision. Decisions are forever (DR); goals are checked off (GR). Keep them in separate files for that reason — see [[feedback_uml_is_contract]] for the parallel idea that UML is the contract, not the running commentary.

## Scope discipline — read this first

**Goals are always project-scoped by file location.** They live in `./Docs/Goals/` inside the project's own repo. The skill never looks outside the current working project. There is no machine-wide goal registry, no cross-project lookup, no global ID prefix. GR-001 in GitEasy is unrelated to GR-001 in PesterForge.

If a Claude session ever surfaces a goal from a sibling project, that is a bug — flag it, do not act on it.

## When to write a GR

Lean toward writing one when:
- The outcome is non-trivial — multiple work-items, multiple sessions, or spans a phase
- "Done" is not obvious from the code — acceptance needs to be spelled out so the team agrees when we're there
- Keith wants accountability against drift — a checkable target that resists scope creep
- You want to use `/goal` to drive toward it (the GR becomes the source of truth for the condition)

Skip a GR when:
- The work is a single trivial change (just do it)
- The acceptance bar is "the test suite passes" with no additional context (use `/goal` directly with no GR)
- The outcome is a personal/business question outside the engineering domain (see [[feedback_business_domain_boundary]])

## Template

```markdown
---
id: GR-NNN
title: <short imperative — "Ship Show-Diagnostic command", not "showdiag work">
status: OPEN | IN-PROGRESS | MET | ABANDONED
phase: <project phase number or "ongoing">
opened: YYYY-MM-DD
closed: YYYY-MM-DD       # only when MET or ABANDONED
linked-drs: [DR-NNN, DR-NNN]
linked-plan: <path/to/plan.md or "n/a">
---

# GR-NNN — <Title>

## Why
<one or two paragraphs: what motivates this goal — the user pain, the
strategic reason, the constraint it satisfies. Plain English. No jargon.
This is the part future-Keith will read first.>

## Acceptance criteria — autonomous (`/goal` drives these)
<Claude-verifiable items only. Each must be checkable from a tool call
Claude can run unaided: file content, exit code, test count, frontmatter
value, git state. These get rendered into the `/goal` condition string.>

- [ ] <criterion 1 — e.g. "All 21 commands have at least one realistic .EXAMPLE">
- [ ] <criterion 2 — e.g. "Pester test count >= 460 and all green on PS 5.1 and PS 7">
- [ ] <criterion 3 — e.g. "`Tools\Invoke-IgPSSA.ps1 -FailOnFinding` exits 0">

## Acceptance criteria — human-gated (STOP loop, hand off to Keith)
<Items that require Keith to click, paste, log in, generate a token,
check a web UI, or run an interactive flow. NEVER rendered into the
`/goal` condition string. When the autonomous loop reaches a dependency
on one of these, it prints the instructions, logs the handoff, and
exits — it does NOT poll. Omit this section if all criteria are
autonomous.>

- [ ] <e.g. "Keith completes Gmail OAuth in browser — refresh token lands in SecretStore">
- [ ] <e.g. "Keith verifies inbox count unchanged in Gmail web UI before/after run">

## Non-goals
<what this goal explicitly does NOT include — protects against scope creep.>

## Linked work
- Plans: <if any plan files exist, point at them>
- Decisions: <DRs this goal depends on or motivates>
- Phase: <if part of a larger phase plan>

## Status log
<append-only. One line per status change with date and evidence.>
- YYYY-MM-DD opened OPEN
- YYYY-MM-DD → IN-PROGRESS (started by <branch/PR/session>)
- YYYY-MM-DD → MET — evidence: <tool call, commit SHA, test run, file path>
```

## File layout

- One index file: `Docs/GOALS.md` — one line per goal, status table
- One file per goal: `Docs/Goals/GR-NNN-slug.md`
- Flat — no per-phase folders. Phase lives in the `phase:` frontmatter field. Filter by reading frontmatter.
- IDs are per-project. No global prefix.

## Status conventions

- `OPEN` — written, not yet being worked
- `IN-PROGRESS` — work has started; cite the branch / session / DR that initiated
- `MET` — acceptance criteria all checked, **and the body cites the tool-call evidence that proves each one** (see anti-stealth-completion rule below)
- `ABANDONED` — explicitly killed; cite the reason (priorities shifted, premise wrong, scope absorbed by another GR). Never just delete a GR — abandoning is its own outcome.

## Anti-stealth-completion rule (load-bearing)

A GR can only flip to MET when the body of the GR cites the specific evidence — a test-run output, a commit SHA, a file path, a `/goal` evaluator pass — that proves each acceptance criterion. Same discipline as [[feedback_no_stealth_completion]]. If you cannot cite the evidence, the goal is not MET; it is still IN-PROGRESS or it is ABANDONED.

This is what makes the GR ledger trustworthy across sessions. A "shipped" claim without evidence is just vibes.

## Autonomous-vs-human-gated criteria (load-bearing)

Acceptance criteria split into two structural kinds. The split is required, not stylistic.

**Autonomous criteria** — verifiable from Claude's tool calls alone: file existence, frontmatter values, test runner exit codes, PSSA output, `/goal` evaluator passes, git state. These go in the `/goal` condition string because the loop can determine pass/fail on its own.

**Human-gated criteria** — depend on Keith performing an out-of-band action: clicking through OAuth, pasting an app password, checking a web UI, generating a token, running an interactive installer. These **must NOT** appear in the `/goal` condition string. The Haiku evaluator can't verify them, can't cause them, and will poll waiting for a state change that never comes — burning tokens until the loop is force-killed.

When a GR has criteria of both kinds, the two sub-sections under `## Acceptance criteria` (see Template above) keep them physically separate. The `/goal` condition is rendered ONLY over the autonomous block.

**Loop-exit rule:** when work reaches a human-gated dependency before the autonomous criteria are all met, the right move is: print the human's instructions, append them to the GR's status log, and **exit the loop entirely**. Conversation resumes when Keith reports the human-gated step done. Never poll. Never wait. Per [[feedback_goal_loop_human_gated]] (link hyphens fixed to underscores 2026-08-15).

**Why this is load-bearing:** 2026-05-20 InboxGroomer GR-001 mixed three OAuth / app-password / web-UI criteria into a single acceptance block. `/goal` was handed the whole block as its condition, polled the Haiku evaluator waiting for state Keith hadn't produced yet, and burned tokens. Keith told it to stop multiple times; the runtime did not honor the stop. He had to close the window. The design fix is here — never let a human-action criterion enter the autonomous loop's condition string.

## Talking to shipped `/goal`

The Claude Code `/goal` command (v2.1.139+) takes a verifiable condition string and loops until a Haiku-class evaluator says it holds. The GR's **autonomous** acceptance criteria are the source for that string.

When Keith says "drive toward GR-NNN":
1. Read `Docs/Goals/GR-NNN-*.md`
2. **Check the human-gated section first.** If any unchecked human-gated criterion is a prerequisite for the autonomous work, REFUSE to render a condition. Tell Keith what he needs to do first, log it in the status log, and stop. Do not invoke `/goal`.
3. Render the unchecked **autonomous** criteria into a single condition string, joined with " AND ". Human-gated items are excluded by construction.
4. **Show Keith the rendered condition first.** Do not auto-invoke `/goal`. The evaluator is a small fast model and can be wrong; Keith needs eyes on what's being checked.
5. On his go-ahead, hand off to `/goal <condition>`
6. If `/goal` work reaches a new human-gated dependency mid-loop, the loop must exit: print instructions, log them in the GR status log, return control to Keith. Never poll for human-produced state.
7. When `/goal` clears (autonomous condition met), update the GR status log with the evaluator's confirmation as evidence. The GR flips MET only when both autonomous AND human-gated criteria are all checked (and evidence is cited per the anti-stealth-completion rule).

Manual-handoff is the default until Keith has used the loop enough to trust the evaluator on his work. See trade-off rationale in the source conversation.

## How this skill assists

When Keith says "I want a goal for X" or "let's write a GR for Y":
1. Read the current `Docs/GOALS.md` to pick the next ID
2. Ask Keith for: why this matters, what the acceptance criteria are, what's explicitly out of scope
3. Draft the GR file in plain English — never invent acceptance criteria he didn't name
4. Add the index line to `Docs/GOALS.md`
5. Confirm status is OPEN and stop — no code yet

When Keith says "what's the status of GR-NNN" or "where are we on X":
- Read the GR file and report status verbatim, including the most recent status-log line
- If acceptance criteria appear checked but the status is still IN-PROGRESS, flag the gap — don't auto-flip

When Keith says "drive toward GR-NNN":
- Render the acceptance condition, show it, wait for go, hand off to `/goal`

## What this skill does NOT do

- Does not invent goal content. If Keith hasn't told you the why or the acceptance criteria, ask — don't fill in with plausible-sounding text. This is the anti-vibe rule applied to goals.
- Does not auto-flip GRs to MET without cited evidence.
- Does not look at goals outside the current project's `Docs/Goals/` directory.
- Does not auto-invoke `/goal`. Renders the condition; Keith confirms.
- Does not duplicate the DR system. If the question is "should we do X this way or Y way," that's a DR (use `dr-author`). A GR is "we are driving toward outcome Z."
