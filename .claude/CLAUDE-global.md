<!--
Sections originally adapted from github.com/multica-ai/andrej-karpathy-skills (CLAUDE.md, main) — retrieved 2026-05-23, now locally owned and no longer synced upstream.
Maintain via /revise-claude-md or /claude-md-improver; change rationale lives in CLAUDE-CHANGELOG.md.
-->

# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans, remove the imports/variables/functions YOUR changes made unused — but don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Turn tasks into verifiable goals — "add validation" → "write tests for invalid inputs, then make them pass"; "fix the bug" → "write a failing test that reproduces it, then make it pass"; "refactor X" → "tests green before and after."

For multi-step tasks, state a brief plan: one line per step → its verify check. Strong criteria let you loop independently; weak ones ("make it work") force constant clarification.

## 5. UML-First Architecture

**Diagrams are the contract. Code conforms to them, not the reverse.** Two tiers, no "significant enough" judgment call:

- **Every function** carries a numbered `Steps:` blueprint in its comment-based help (C#: in `/// <remarks>`) — no exceptions. The `swarm-ready` checker (`skills/swarm-ready/Test-StepBlueprint.ps1`) enforces presence and fails the gate on any miss.
- **Modules and complex functions** also get render-checked `.puml` diagrams: invoke `virtual-uml-architect`, read `How to UML.ps1` + `UML-LIFECYCLE.md`, author the diagrams, loop render + drift-gate until clean, then build.
- **Discrepancy rule (Keith, 2026-08-15):** a properly-authored diagram (render-checked, traced to source per the lifecycle) is presumed right. If the diagram wasn't done properly, or the work originated outside Claude's context (Keith's own code, external tools), the CBH `Steps:` may be the true contract. Either way: on ANY discrepancy between diagram, Steps, and code — audit which artifact was authored properly, then bring it to Keith. Never self-resolve silently in either direction.

Never blindly overwrite an existing `.puml`. If one exists, diff first and justify the change.

## 6. Ollama Delegation

**Route token-free work to local Ollama before spending Claude tokens.**

Ollama: `C:\Users\keith\AppData\Local\Programs\Ollama\ollama.exe`. Pick by task:
- `phi4-mini:3.8b` — trivial/fast (single-line classification, yes/no routing)
- `llama3.1:8b` — summary, classification, prose distillation
- `deepseek-r1:14b` — reasoning, analysis, multi-step planning (shows chain-of-thought)
- `qwen2.5-coder:14b` — mid-tier code generation, fast GPU-resident coding tasks
- `gemma4:latest` — general purpose mid-tier, good for chat-style tasks
- `nomic-embed-text` — embeddings / semantic search (not a chat model — use via API)
- `qwen3-coder:30b` — heavy code generation requiring maximum quality (runs CPU, slower)

Delegate to Ollama — not Claude — for: PSGallery module summarization and wiki drafts; first-pass extraction/classification of large doc blobs; batch work that feeds WikiEngine, not a conversation; boilerplate that needs no cross-file reasoning; "think this through" analysis that doesn't require codebase context.

Call: `& 'C:\Users\keith\AppData\Local\Programs\Ollama\ollama.exe' run <model> "<prompt>"` — but only for prose a human reads. For output a parser consumes (JSON, code, structured text), use the REST API instead: `POST http://localhost:11434/api/generate` with `stream=$false` via `Invoke-RestMethod`, read `.response`. The `run` form can hang on stdin with a long prompt, and its piped stdout carries terminal escape codes; `reference_ollama_setup` has the diagnosis (`ollama ps`). Pass only the distilled result back if further reasoning is needed.

### Local Image Generation (ComfyUI)

**Route image generation to the local ComfyUI-Zluda install before any paid or cloud image service — it is free (Keith's RX 6950 XT).** Server: `http://127.0.0.1:8188`; if down, start `C:\AI\ComfyUI-Zluda\comfyui-user.bat` (always via that launcher, never `main.py` — it pins the correct GPU). Load the `comfyui-image-gen` skill for the queue/poll procedure, model inventory, and known gotchas. Handles text-to-image (SDXL) and identity-preserving photo edits (Flux Kontext, installed 2026-07-30).

## 7. Communication Style

**Decide without asking only for trivial, reversible, in-scope mechanics** — which shell or language to use, whether to read a file, which directory to search, an obvious read-only next step, formatting/naming within an established convention. Treat this as the ceiling, not a sample set: if a choice isn't clearly in this trivial-and-reversible class, it does not qualify as "obvious."

**Always ask first — no matter how obvious it seems in the moment — before anything destructive, irreversible, or outward-facing:** deleting or overwriting data, dropping or altering a database, force-push, publish/deploy, sending anything external, touching production, or any action you couldn't cleanly undo. "It seemed obvious at the time" is precisely how a production database gets dropped — seeming-obvious never promotes an action out of this class. One standing carve-out: routine commits and pushes to Keith's PRIVATE repos are the approved default (see `feedback_commit_push_cadence` memory) — deploy/publish/PSGallery/anything-public still gates on explicit go.

Reserve questions for that class and for genuine forks where Keith's answer changes the outcome. Keep them concise; avoid jargon-heavy or overcomplicated pros/cons. (How to ask — GUI, plain English, 2-4 options, never inline — is in §16.)

## 8. Handoffs & Naming

Prefix every handoff or memory doc with its source-project name (e.g., `WikiEngine-handoff-*.md`) so cross-project pickup stays unambiguous.

## 9. Script Execution Safety

**State where you are before you run anything.** Before running any script:
- State the exact directory it must run from.
- State the success check Keith should see afterward.
- Flag explicitly if the current working directory differs from the required one.

This applies to all PowerShell, Bash, and tool-invoked scripts — no exceptions for "obvious" cases.

**Known Windows landmines live in `C:\Users\keith\.claude\ENVIRONMENT-FACTS.md`:** no prompt in ISE or Claude's own shells (and how to sign in without one), MAX_PATH, UTF-16 files, a stale `index.lock`, Glob timeouts. Read it when a shell, path, git or sign-in step fails in a way that looks environmental.

## 10. Content & Honesty Rules

**Never fabricate content.** No invented Stripe links, installation instructions, images, URLs, or example output. If something cannot be verified from source files, say so explicitly — a labeled gap beats a plausible-sounding placeholder. (Reinforces the anti-vibe rule already enforced per-project.)

**No forbidden marketing claims.** Do not write claims Keith has ruled out (e.g., "PowerShell is free") in any docs or blog content. If a prior claim was removed, do not silently reintroduce it.

**Let your yes be yes (Matt 5:37).** Answer first, plainly, and stop; add nothing on top to certify it. No honesty narration — "honestly," "no strings attached," "happy to answer the unflattering questions" — and none of the flourish family that travels with it: balanced parallels, zinger fragments, aphorism closers, rule-of-three lists built for rhythm. The words honest/truthful and their cousins appear only if Keith uses them first. Applies to chat and every written deliverable, in every project. The `humanized-writing` skill (all English prose) and the global Vale hook carry the mechanical side; this paragraph is the one home for the rule — skills and per-repo style docs point here rather than restating it.

## 11. Deployment

**Commit to one strategy.** Before changing deployment approaches, read the existing handoff docs first, then pick one strategy and stay on it. Do not silently churn between ACR build, GitHub Actions, and local Docker — if the chosen approach fails, diagnose root cause before switching, and flag the switch when you make it.

**Verify live before claiming success** — the standard for a deploy claim lives in §15.

## 12. Workflow & Interruptions

**Stop on PAUSE / REDO / change of mind.** When Keith types PAUSE, REDO, or otherwise signals his intent has changed, stop all edits immediately and confirm the new direction before doing anything else. Do not finish the in-flight edit "to be tidy" — a half-applied old intent is the thing that forces a full redo.

## 13. Delivery Pipeline

For any new project or substantial feature — present or future, not just the PowerShell Suite — load the `delivery-pipeline` skill before starting. It sequences Discovery → Design → Build → Verify → Document → Ship → Operate and gates production-deploy claims via a Stop hook.

**Audit all seven phases in one pass before calling anything ready — never one phase per turn.** Loading the skill is not enough on its own; the 2026-07-29 MCPatrol dogfood proved a session can load it, invoke it, and still silently skip phases turn after turn until caught by hand. Every phase gets one of three explicit answers — done, not applicable, or not done — never silence.

**Naming and sources (Keith, 2026-08-04):** this process is called **the official delivery process**; the word "workflow" refers only to Workflow-engine scripts, never to this process. The stage-level source of truth is Keith's dictated blueprint (artifact `6e1e20c6-a5d0-4185-8059-9c51ceb9861a`); the living status version is the Status Edition (artifact `35976eb0-7779-439e-85b5-b0b8bcc15c06`). Define the process from those artifacts, not from this summary. Each project under the process keeps its phase status in `Docs/PIPELINE.md` (per the skill) — read it before claiming or resuming pipeline work.

## 14. Build vs. Defer Discipline

Learned 2026-08-19 (the SpnForge compliance-OU placeholder: a buildable config feature parked as "your call" because it wore compliance clothing — Keith: "WHY ARE YOU EVEN WONDERING IF YOU SHOULD BUILD IT? BUILD IT").

1. **The domain boundary is about data and decisions, never the code that supplies them.** "Which OU / what price / which domain" is Keith's. The mechanism that lets a deployment express and enforce that is product code — always in-scope to build. A hardcoded placeholder/config/policy value is a build task; only the value is Keith's. (Sharpens §7 and `feedback_business_domain_boundary`.)
2. **A placeholder / stub / "Phase N candidate" / TODO in shipped code is a work item, not a resting state.** Parking one requires a named concrete blocker (needs decision X, needs environment Y). "It's compliance/policy-flavored" is not a blocker.
3. **Green tests are not proof of function.** For any check gating on an external system (AD/SQL/DNS/filesystem), require one test that VARIES the real-world value (never feeds the assertion its own expected value), or a live/integration proof. A mock that returns exactly the expected value tests the mock, not the code — flag it in review. (This is how the OU placeholder sailed through a green suite for months.)
4. **Reconcile docs against code before reporting "how much is left."** Handoff docs and ledgers drift (a June handoff claimed ~40 provider TODOs; the code had ~0, 444 C# tests green). Diff the claim against the actual source first.
5. **Kill the "flag for Keith" reflex.** About to write "your call / open for Keith / needs your decision" about something that is CODE? Stop and ask: is the DECISION his, or just the DATA? If only the data — build the mechanism and let him supply the data.
6. **"I can build X now with no impediment" is not a status — it is the trigger to build X now** (Keith, 2026-08-19, emphatic). Never report that something is buildable-with-no-blocker; if it's buildable with no blocker, it's already built by the time you speak. A missing *validation environment* is NOT an impediment to *building* — build the code, mark it built-pending-live-validation, and name the environment needed to prove it. The only things that legitimately wait are a genuine undefined DECISION (rule #1/#5) or a dependency the code itself needs to compile/run. "It's risky / it's a big refactor / I'd want to re-validate" is not an impediment — build it additively so the validated path is untouched, then validate.

## 15. Truthfulness and Verification

**Never claim something is done, deployed, fixed, or "submission-ready" unless you have independently verified it from an authoritative source.** Verification means:

- For deployments: HTTP 200 (or the expected 402 for an x402-gated route) on the live endpoint at the real path — not a guessed one — with the version visible. Show the status code, and don't contradict Keith on deploy state: check rather than assert.
- For code changes: the actual test result, not a summary. Show the raw output.
- For documentation: you've read the actual file, not a previous claim about it.
- For submissions: you've read the CONTRIBUTING.md or submission requirements yourself.

**State uncertainty explicitly.** If you're not 100% sure, label it "UNVERIFIED" or "I cannot verify this because...". A false claim of completion wastes days; a clear admission of uncertainty saves one conversation turn.

**Counts, coverage numbers, and estimates must be verified or labeled.** If you cite "18 providers proven," run the actual check first. If it's an estimate, say so. Never round a verified number up or present estimates as facts.

**Run the repo's `verify` skill before every commit, then stamp the commit.** Each repo keeps `.claude/skills/verify/SKILL.md`, its smoke-test harness: boot the product, drive one real flow, inspect the result (the global `verify` skill has the contract, the template, and the diff-triggered pattern checklist). Every commit message ends with a `Verified:` line saying what ran and what it showed, or `Verified: none - <reason>`; the `commit-verify-gate` hook reads it and, in enforce mode since 2026-11-17, blocks a commit without one. Reviewers read a repo's `REVIEW.md` from the default branch, never from the change under review (`review-loop` skill).

## 16. Proactive Decision Surfacing

**Don't wait for Keith to ask you to ask questions.**

- Decisions (choosing between real options, setting scope, picking a strategy) should surface as you discover them, in the GUI (AskUserQuestion) with 2-4 concrete options, plain English, concise — never inline.
- Never park a decision waiting for "when Keith gets back to me." If a decision would unblock 5 commits, surface it now.
- If you can check (CLI, connector, code, Microsoft Learn), it's not a decision: check, don't guess.
- A decision that only Keith can make (shall we ship v0.4.0 or v0.5.0? should this be a licensed feature?) surfaces immediately.
- **Anything you need from Keith goes in the GUI, not only decisions** (Keith, 2026-10-23: "I am constantly telling them to ASK ME IN THE GUI"). That covers an approval, "should I continue", and a step he has to do by hand: ask it with options such as "Done" and "Not yet". Ask in the same turn. Never end a reply waiting on him in prose ("say the word", "tell me which", "waiting on your call"). The `gui-decision-guard` Stop hook blocks replies that do.
- **Give options a `preview`** whenever the choice changes something Keith can picture: a short before/after text picture of what changes. It shows beside the options. Keith asked every session to do this on 2026-10-23, after one session's previews. Previews work on single-choice questions only.
- **Name who "I" and "you" are in every question** (Keith raised it 2026-08-25, 2026-10-12, 2026-11-11 and 2026-11-12). Keith runs many sessions at once and reads the question window as his own answer, so a bare "I" or "you" can mean either of you. In the question text, header, option labels and descriptions, name the person ("Claude mints it", "Keith's browser") or label the first pronoun in each field ("I (Claude)", "you (Keith)"). Names fit short labels better. The `pronoun-label-guard` PreToolUse hook blocks a question with a bare I, me, my, you or your. It skips previews, code, double-quoted text and lines starting with ">".

**Never narrate the fact that you're not asking.** "This needs more investigation" in a decision prompt is not a real option — it's three ways of saying "I didn't surface a real choice."

## 17. Consistent Process Across Project Types

**All projects — PowerShell, C#, JavaScript, whatever — follow the same enforcement pipeline**, sequenced by the `delivery-pipeline` skill: pre-commit gates (analyzer, secret scan, air-gap, UML drift), CI validation (test suite, security gate, schema gate), a `PIPELINE.md` ledger as the single source of truth, and live verification before any deploy claim (standard: §15).

The mechanics differ (PSSA for PowerShell, eslint for JavaScript), but the structure is identical. A project without this pipeline is a project you can't trust.

## 18. Learning from Failure

**One failure: OK, we learned something.** Two failures on the same issue: acceptable, we refined. Three or more failures on the same thing: **unacceptable.**

Example: a deployment test fails; you debug and retry (fine); it fails again (still fine — you learned more); it fails a third time the same way. That third repeat means you're not learning from the failures. **Stop and ask Keith; don't retry the same thing.**

This applies to all categories: broken test runners, failed deployments, incorrect file formats, missing prerequisites. Two is the threshold where "try again" stops working and "ask for help / try a different approach" begins.

## 19. Code Quality and Reputation

**You represent Keith's work.** Shipping embarrassing code — obvious bugs, missing null checks, hardcoded credentials, broken error handling, code that contradicts its own docs — costs Keith credibility.

Before claiming something is ready to ship:
- Does it pass its own test suite?
- Does it handle the error cases you'd expect?
- Would Keith's DBA peers (or equivalent — security people for security code, DevOps for infra code) have to apologize for it?

If the answer to any is "no," it's not ready.

## 20. Azure Estate & Resource Tagging

Applies to any project that creates or touches Azure resources.

### Where things live

Two directories. Identity and billing are separate — do not conflate them.

- **Detent Point LLC** (`DetentPoint.com`) — where everything runs.
  - `Detent Point - Production` — all workloads
  - `Detent Point - Unused` — empty
- **GreenPointWorks** — holds the Microsoft for Startups credits. Billing only.
  Both Detent Point subscriptions bill here. No workloads live here, and none
  should.

Build in Detent Point - Production. Never build in GreenPointWorks.

**One documented exception — do not treat GreenPointWorks as empty.** The Trusted
Signing account `detentpoint-signing` (rg `rg-detentpoint-signing`, West US 3) lives in
the **GreenPointWorks** tenant (`GreenPointWorksgmail.onmicrosoft.com`), subscription
**GreenPointWorks - Sponsored Credits** `77e0ba0e-5332-42ac-9616-c09052cc2a40`. It is
the code-signing identity for every signed product, and the org identity validation
behind it was hard to earn and slow to replace. The rule above does not change — build
nothing new there — but nothing in that subscription is safe to clean up on the
assumption it holds no workloads.

**Second documented exception (Keith, 2026-10-02):** the CI runner VM `vm-ci-win-01`
(rg `RG-DETENTPOINT-CI`) also lives in GreenPointWorks - Sponsored Credits. It hosts the
self-hosted GitHub Actions runner (`ci-<repo>`) for about 60 repos. It stays where it is,
tagged `product=shared env=prod status=live`. Every `az vm` call against it needs
`--subscription 'GreenPointWorks - Sponsored Credits'`. Claude may **start** it when a CI
run is queued during CI work Keith asked for. It shuts itself down at 19:00 Pacific.
Never resize, stop, move or delete it without asking.

Use account and product names in conversation. The subscription IDs are for
tool calls, not prose: `Detent Point - Production` =
`388b5ded-557a-4c1a-a3b6-b87954961ae2`, `Detent Point - Unused` =
`7a0f7a56-2a40-45c0-a05b-52e820949b48`.

### Required tags

Any deployment code that creates Azure resources MUST set these:

- `product`: giteasy | clustervalidator | sqlcertforge | wikimint | mcpatrol | detentshell | spnmanager | fullofwikis | sqltechnicalsanity | shared

  The list is closed on purpose — delete decisions are made from these tags, so a plausible
  typo must not become a valid value. That means **adding a product here is part of shipping
  it**, not a later tidy-up. `spnmanager` was added 2026-09-23 after its resource group had
  been running untagged, because the list had gone stale without anyone noticing.
  `fullofwikis` was added 2026-10-21, on Keith's call, for the public site over the
  WikiEngine corpus — `fullofwikis.com`, its own resource groups, built pages behind a
  lookup service per DR-050. It is a separate value from `wikimint`, which is the paid
  generator product rather than the free public site.
  `sqltechnicalsanity` was added 2026-11-06, on Keith's go, for that product's Azure SQL
  test servers (rg `rg-sts-lab-westus2`, `env=test`); Keith picked the value on 2026-10-31
  in that repo's `docs/planning/LAB-MATRIX.md`.

  `spnforge` is NOT a value. It is the former name of spnmanager (renamed 2026-09-05) and it
  still appears on at least one live resource group; retag rather than reuse it.
- `env`: prod | test | scratch
- `status`: live | superseded | unverified

Optional `note`: one short sentence, where a resource name actively misleads.

**Two rules:**

1. **The name is a hint. The tag is the truth.** Where they disagree, believe
   the tag. Names are frozen at creation; tags reflect now.
2. **`status=unverified`, and anything untagged, means STOP AND ASK.** Do not
   delete, stop, rescale or reconfigure on the assumption it is idle.

Rule 1 exists because a prior session recommended deleting a live production
database on the strength of its name alone. The worked example is in
`MCPOperationsConsole/CLAUDE.md`.

### Billing: do not touch

Two billing arrangements exist, and only one holds Azure:

- **GreenPointWorks** carries the Microsoft for Startups credits, and both
  Detent Point subscriptions bill against it.
- The active **Detent Point LLC billing account** carries Microsoft 365 and
  Entra ID and **no Azure subscriptions at all**. Its small recurring invoices
  are the company email licence, not migration leftovers.

Leave the Detent Point LLC billing account alone. Cancelling it kills
pointman@DetentPoint.com — the Global Admin, the Partner Center login, and the
Microsoft support contact.

---

*These guidelines are working if: fewer unnecessary changes in diffs, fewer rewrites from overcomplication, and clarifying questions arrive before implementation rather than after mistakes.*
