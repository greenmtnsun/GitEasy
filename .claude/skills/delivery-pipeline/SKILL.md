---
name: delivery-pipeline
description: Use for ANY project of Keith's, present or future — not just the PowerShell Suite — when starting new work, scoping a feature, or claiming something is ready to ship. Covers the full path from a one-line idea to something live and watched in production — Discovery, Design, Build, Verify, Document, Ship, Operate. Auto-triggers on "new project", "let's build X", "start a repo", "is this ready to ship", "deploy this", or any greenfield/substantial-feature kickoff. A coordinator, not a reimplementation — each phase names the sibling skill that actually does the work. Pairs with the pipeline-gate-stop Stop hook, which mechanically blocks a production-deploy claim unless it carries a `<!-- pipeline-complete -->` or `<!-- pipeline-exception: reason -->` marker.
---

> See also: `honest-completion` + `verify-claims-on-disk` for the completion-claim discipline this pipeline assumes throughout. `goal-author`, `dr-author`, `virtual-uml-architect`, `virtual-tester`, `code-review`, `virtual-security-reviewer`, `review-loop`, `ui-design-reviewer`, `run`, `release-qa-passes`, `virtual-compliance`, `blog-content-pipeline` for the phases below — this skill sequences them, it doesn't replace them.

# Delivery Pipeline

Keith's standing instruction, 2026-07-28: *"this is bigger than my suite, I want it for every project now and future... I want it enforced in a way that new claudes aren't shocked."* This skill is the always-visible, cross-project answer — it shows up in every session's skill list the same way `software-creation` or `air-gap-discipline` already do, regardless of which repo is open.

## The seven phases

Each phase names the skill/tool that actually does the work — this skill's job is sequencing and making sure nothing gets silently skipped, not duplicating anyone's logic.

| # | Phase | What happens | Who does it |
|---|---|---|---|
| 1 | **Discovery & Framing** | Plain description, why, done-means. Feasibility is a well-framed prompt at kickoff, not a formal stage. Compliance/legal is the existing `/comp…` skills or the legal persona directly — ask, don't formalize. | `goal-author` |
| 2 | **Design** | Architecture choices written down before code. Diagrams are the contract. When the project has a UI: mockups for every screen state, then a **UI design review loop** before Build starts. | `dr-author`, `virtual-uml-architect`, `ui-design-reviewer` |
| 3 | **Build** | Code, air-gap-clean, provenance-stamped. | `function-design`/`swarm-ready` (PowerShell) or the stack's own equivalent convention, named explicitly |
| 4 | **Verify** | Static analysis, unit, integration, **code review loop**, **security review loop**, visual UI walk, **UI review loop** (when there is a UI), adversarial input, performance/load, accessibility. **No selective test strategy — see below.** Release-cadence QA passes (test-suite audit per milestone, regression pack per release cut, SFDIPOT per new feature) — each run logs an evidence row in the ledger. | `compliancesuite`, `code-review`, `virtual-security-reviewer`, `ui-design-reviewer`, `run`, `release-qa-passes` |
| 5 | **Document** | Wikis (honest-gap stance), UML re-sync, blog post once it's real, changelog. | `wikimint-dogfood`, `blog-content-pipeline` |
| 6 | **Ship** | Cloud target, dev deploy, **prod deploy — hard gate, see below.** | — |
| 7 | **Operate** | Telemetry/observability, rollback plan, retro. The phase most pipelines forget. | — |

## Rule: no drip-feeding — audit and disclose all seven phases in one pass

Learned the hard way, 2026-07-29, on the MCPatrol Android release: this skill was
loaded, invoked, and still failed in practice — Discovery and Design got silently
skipped for a full day because each turn only checked the one phase that seemed
relevant in the moment (tests, then the Play Console checklist, then Document) and
declared success without ever auditing the other six. Keith caught it three separate
times by hand ("isn't there a whole set of things besides just this?", "did he follow
all the other workflow things, like uml", "there is MUCH more to it than you keep
asking of it") before it got fixed. That's the failure mode this rule exists to kill.

**When this skill is in scope for a non-trivial change, audit all seven phases in one
pass before saying anything is ready — not one phase per turn, not "I'll check the
rest later."** For each phase, the answer is one of exactly three things, stated
explicitly: **done** (with evidence), **not applicable** (with a one-line reason), or
**not done** (named as a gap, not silently omitted). A phase you forgot to check is
indistinguishable, from Keith's side, from a phase you're hiding — treat "I didn't get
to it" as unacceptable as "I decided not to mention it."

This is mechanically backstopped for the one highest-stakes moment: the
`pipeline-gate-stop` Stop hook requires the `<!-- pipeline-complete: ... -->` marker to
carry actual phase-by-phase content (as of 2026-07-29 — a bare `<!-- pipeline-complete
-->` tag no longer satisfies it, for exactly this reason). But the hook only fires on
literal production-deploy language — it does not catch Internal Testing, a staging
rollout, or a `main`-branch push that auto-deploys under some project's own
convention. Don't rely on the hook to catch what a bare disclosure habit should have
caught in the first place.

## The pipeline status ledger — the missing piece that makes "get the rest done" work

Keith, 2026-07-28: *"only forced to do what it didn't do yet, not start coding for
the first time like no code was written."* That requires something that can answer
*what's already done* without a human enumerating it — a behavioral rule alone can't,
because nothing persists between turns or sessions. This is the piece that was missing
until 2026-07-29.

**Every project this skill applies to gets one file: `docs/PIPELINE.md`** (repo root if
there's no `docs/`). One row per phase/sub-item, three columns: Status (`Done` /
`N/A` / `Not done`), Evidence (what proves it — a file path, a commit, a test count),
Date. In a repo that holds more than one product, each product keeps its own ledger in its own
folder: in WikiEngine, WikiMint's is `WikiMint\Docs\PIPELINE.md`, and the root one belongs to the
Insights generator. Pass that path to the `delivery-pipeline` workflow as `ledgerPath`.
Whoever does the work updates the ledger **in the same pass as the work**, not as
a separate bookkeeping step done later — a ledger that drifts from reality is worse
than no ledger, because it's trusted.

This is what makes a bare instruction like *"get the rest done"* actually work: any
session — this one, a sibling, a fresh one tomorrow — reads `docs/PIPELINE.md` first,
treats every `Not done` row as the real task list, and updates statuses as it closes
them out. Nobody has to re-enumerate the gap by hand.

**Named limitation:** the `pipeline-gate-stop` hook does not read this file. Parsing
arbitrary project markdown reliably from a lightweight PowerShell Stop hook isn't
practical, so the ledger is convention-and-discipline-backed, the same trust model as
everything else in this skill — not mechanically cross-checked. If a session updates
the ledger dishonestly, that's a `verify-claims-on-disk` problem, not something this
file structurally prevents.

## Rule: exhaustive test coverage, no selective filter

Confirmed 2026-07-28 (recorded here — the `[[feedback_exhaustive_testing]]` memory file this cited was never created/is gone, verified 2026-08-15; this skill text is the rule's home): do not propose skipping test coverage as "low-risk" or apply a mock-vs-real judgment call as the default. Test everything. Past claims of "done" or "properly stubbed" have turned out false too many times to trust a discretionary skip — see `honest-completion`. If a real time/cost tradeoff exists, surface it explicitly and let Keith choose to cut scope; never default to cutting it silently.

## Rule: reviews loop until clean

Adopted by Keith 2026-11-14. Four reviews run as loops: UI design review (Design, when there is a
UI), code review, security review and UI review (Verify, the last when there is a UI). The rules
live in `review-loops.json` beside this file, so any orchestrator can read them; the control flow
is drawn in `uml\01-activity-review-phase.puml` and `uml\02-activity-review-loop.puml`. The
`review-loop` skill is the entry point for running a loop from any orchestration, and the
`ui-design-reviewer` skill is the reviewer for the UI design and UI loops (both added 2026-11-15).

- **Reviewer:** a fresh agent every round, never the one that built or repaired the work. From
  round 2 it reports on every prior finding by id before it looks for new ones.
- **Repair:** the builder repairs each finding or proposes a waiver with a written reason. Tests
  and static analysis re-run, then every review in that phase looks again at the changed files.
- **Exit (Keith's rule):** no finding left open. A finding closes when it is repaired, or when the
  next reviewer accepts its waiver. Every waiver goes in the project's ledger: `docs/PIPELINE.md`,
  or the `ledgerPath` the workflow is given.
- **Stop and ask Keith:** a finding still open after 2 repair rounds (CLAUDE.md section 18); a
  medium, high or critical finding still open at the round cap; a diagram, `Steps:` or code mismatch
  (CLAUDE.md section 5, never repaired in the loop); a builder escalation; or a critical or high
  finding someone wants to waive. A stopped stage is never marked clean, and no later phase runs.
  The stop lists each finding's location, evidence and suggested repair, and every open item the
  phase agents left for Keith.
- **Stop on an escalation (Keith, 2026-11-15, spec 1.2.1):** an escalation or a proposed critical
  or high waiver stops the loop straight after the repair round, so that round's repairs are not
  re-tested or reviewed. The stop says so. A resume with Keith's ruling reruns that repair round.
- **Round cap with only low findings (Keith, 2026-11-15):** they go to the ledger as open items for
  Keith, and the run goes on. Nothing else goes in the ledger: not a stop, a ruling or a pending
  resume.
- **After a stop (Keith, 2026-11-15):** Keith rules on the listed findings; resume the run with the
  same args plus `keithRulings: [{ id, ruling }]`. The next repair round carries out each ruling,
  then one more fresh review checks it, past the cap if need be. Earlier agents replay from cache.
- **Small item (Keith, 2026-11-15, spec 1.2.0):** when Build changed one source file under 200
  lines (test files not counted), Verify runs one code-and-security loop, with one fresh reviewer a
  round applying both checklists, and every Verify loop caps at 3 rounds. Anything bigger keeps
  separate code and security loops and the cap of 5. The Design phase isn't sized.

This applies when the process is walked by hand in conversation too: run each review as a fresh
subagent and loop the same way. The round caps (5, or 3 for a small item), code review at level high, and the no-waiver
rule for critical and high findings are defaults Keith can change in `review-loops.json` (then
mirror the change in the workflow script, which cannot read files). After any edit to either, re-run
`node tests\run-scenarios.js C:\Users\keith\.claude\workflows\delivery-pipeline.js` from this
folder and expect `25/25 passed`. The workflow also records the paths already uncommitted when it
starts (`treeAtStart`), so the commit afterwards can leave them out.

## Stack and cloud conventions

- **Stack is named, not detected.** Don't try to auto-sniff PowerShell vs. C# vs. a game engine. State the stack explicitly in the Discovery brief (Goal Record), and let each phase's tooling follow from that — Pester for PowerShell, the project's own framework named explicitly otherwise.
- **Cloud is Azure by default.** AWS is opt-in per component when a project specifically calls for it (e.g. a component of a non-Suite project that's AWS-only) — name it explicitly in Discovery, don't default to it.

## Ship-phase gate: dev auto, prod hard-gated

Dev deploys proceed without a stop. Production deploys are the one place this pipeline mechanically enforces itself — a `pipeline-gate-stop.ps1` Stop hook blocks any turn that claims a production deploy (*deployed to production / live in production / pushed to prod / shipped to production / production deploy complete*) unless the turn carries one of:

```
<!-- pipeline-complete: Discovery=done, Design=done, Build=done, Verify=done,
     Document=done, Ship=this, Operate=done/disclosed -->
```
A bare tag isn't enough (as of 2026-07-29) — say which phases ran, in one pass. See
the no-drip-feeding rule above for why.

```
<!-- pipeline-exception: one-line reason -->
```
Break-glass. See below.

This is in addition to — not instead of — the standing CLAUDE.md rule that any actual production action still needs Keith's explicit go before it happens. The marker documents that the *pipeline* ran (or didn't); it's not the authorization for the deploy itself.

## Exceptions — break-glass, never silent

Keith, 2026-07-28: *"I do want exceptions allowed and how and when should be determined. Like for instance, CRAP, take that out of production ASAP."*

Exceptions exist for genuine production emergencies — an active incident where running the full pipeline first would cause more harm than skipping it. They are **not** a general discretionary shortcut; they don't relax the exhaustive-testing rule above for ordinary work.

How it works:
- Invoke it with `<!-- pipeline-exception: <one-line reason> -->` in the completion-claiming turn. The reason is mandatory — an empty or missing reason does not satisfy the gate.
- The hook logs every use to `C:\Users\keith\.claude\hooks\pipeline-exceptions.log` (timestamp, reason, transcript) and prints it to that turn's output immediately — Keith sees it in the moment, not buried in an archive.
- An exception is a debt, not a close-out. Once the emergency is resolved, the skipped phases (tests, UML resync, wiki, retro) get backfilled — this is exactly what the **Operate** phase's retro step exists to catch. Don't let "it was an emergency" become the permanent excuse for never finishing Verify/Document on that change.
- "How and when" is judged by disclosure, not by the hook — a script can't tell a real incident from a convenient excuse. The mechanism is: it's always visible, always logged, and reviewable by Keith after the fact, the same trust model `honest-completion`'s verified/not-verified markers already use.

## One-shot execution

For work that genuinely warrants running the whole pipeline as one orchestrated pass, the saved Workflow script `ps-module-release-check.js`-style at `C:\Users\keith\.claude\workflows\delivery-pipeline.js` encodes these phases as `agent()`/`pipeline()` stages. Invoke via the Workflow tool when the scope calls for it — this is what lets a session be "empowered to one-shot" a project rather than hand-walking each phase in conversation. Its Design and Verify phases run the review loops above; a stopped loop ends the run early and returns `halted: true` with an `askKeith` line, which goes to Keith in the GUI.

## What this skill does NOT do

- **Doesn't mechanically verify phase artifacts exist on disk.** The hook checks for a marker, not for the actual UML file or test run — that trust model is `honest-completion`'s and `verify-claims-on-disk`'s, not this skill's to reinvent.
- **Doesn't replace any sibling skill's judgment.** It sequences; `virtual-uml-architect` still decides what the diagrams look like, `virtual-security-reviewer` still decides what's a real finding.
- **Doesn't apply Operate-phase ceremony to trivial changes.** A one-line fix doesn't need a Goal Record. Use judgment on scale; this pipeline is for new projects and substantial features, not every commit.
