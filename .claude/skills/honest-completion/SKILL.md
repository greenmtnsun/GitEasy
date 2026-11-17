---
name: honest-completion
description: Use when claiming any unit of work is done, complete, ready, shipped, fixed, landed, finished, implemented, merged, or committed. Codifies the no-stealth-completion discipline — every completion claim must cite the tool call that proves it; every incomplete function carries a `# STUB:` block; sub-agent prompts must carry the no-fabrication preamble. Pairs with `verify-claims-on-disk` (this skill PRODUCES honest claims; that skill VERIFIES other agents' claims). Mechanized in this workspace by the no-stealth-completion-stop Stop hook and the sub-agent-honesty-injection PreToolUse Agent hook.
---

> See also: `verify-claims-on-disk` for the consumer-side discipline (trust no other-agent claim before verifying); `software-creation` §6 for the four-tier confidence model.

# Honest completion

Two failure modes, one rule, because they're the same lie ("I claimed done when it isn't"):

- **Stealth stubs** — handing back partial work as if it were complete.
- **Invented verification** — claiming *verified / tested / works / passes* without citing the tool call that proves it.

Keith named the line directly on 2026-05-12: *"They tell me they are ready to move on... only built a stub, or 20, 30 percent. When I asked if they have code checked they will and nothing is revealed. I'm tired of it."* Two real incidents in the seven days prior (2026-05-06 dispatch claimed 3 fixes that didn't apply; 2026-05-08 overnight scheduled task shipped 0 of 6 fixes) made the cost concrete. This skill treats the rule as an absolute, not a lean-toward.

## When this skill applies

This skill activates the moment a Claude turn contains a completion-claim word:

- *done / completed / finished / shipped / landed*
- *implemented / fixed / merged / committed*

A Stop hook (`no-stealth-completion-stop.ps1`) enforces this mechanically — it blocks any turn that contains a completion word and lacks both `<verified>` and `<not-verified>` markers.

## Rule 1 — Stubs are allowed; undisclosed stubs are not

Any function that is incomplete carries a `# STUB:` block immediately above it. The `# ` prefix is part of the marker so a grep finds these without false positives in string literals.

    # STUB:
    # 1. Validate $Path is a real directory (Test-Path -PathType Container)
    # 2. Return $null instead of throwing when not found (matches Get-Foo convention)
    # 3. Pester test: rejects relative paths
    # 4. Pester test: handles UNC paths
    # 5. Error path: surface ItemNotFoundException with friendly message
    function Get-FooBar { throw "not implemented" }

Rules for the block:

- Each line is one independently testable obligation. Bullet points like "make it work" do not count.
- Tests and edge cases must appear, not just the happy path.
- When an item is implemented AND verified, delete the line **in the same edit** that implements it. Don't let the block lie.
- A function with no `# STUB:` block is a contract that the function is complete and verified.

A repo-wide `grep '^# STUB:'` IS the ledger. Do not create a parallel `STUBS.md` file — it will drift, and the inline block is already the source of truth.

## Rule 2 — Verification claims must cite the tool call

Words like *verified, tested, confirmed, passes, works, handles, validated* trigger this rule. Each one must cite — by one of these canonical shapes — what produced the claim:

| Citation shape | Example |
|---|---|
| **Test ID** | `Invoke-Pester` → `Get-Foo.Tests.ps1 :: It "rejects relative paths" : Passed` |
| **Command + exit + line** | `dotnet build` → `exit 0, 0 errors 2 warnings` |
| **Dogfooded command + observed result** | Ran `Get-Updates` on `C:\Sysadmin\Scripts\GitEasy`; output included `3 commits ahead` |
| **File Read with line range** | `Get-Foo.ps1:42-58` — confirmed early-return on `$null` |

Inspection is not verification. Reading code and reasoning about it is *review* — useful, name it "reviewed," not "verified."

The commit-level form of the same citation is the `Verified:` trailer at the end of every commit message (see the `verify` skill); the `commit-verify-gate` hook reads it.

Bare *I ran the tests* / *looks correct* / *should work* / *appears to handle* without a citation count as invented verification. Crosley's framing: *"Instructions without verification commands are suggestions, not rules."* Anthropic calls this the *"trust-and-verify-later gap"* — name the failure mode so the agent has vocabulary to refuse it under pressure.

## Rule 3 — Bounded retry: two attempts, then stop

If a verification fails, the agent gets **one** fix attempt and **one** retry. If the second attempt also fails, stop and report with full output. Do not loop. Do not silently downgrade the claim to "mostly works." Three or more attempts on the same failure means the assumption is wrong, not the fix.

## Rule 4 — Completion turn requires marker blocks

Any turn where the agent claims a unit of work is *done / complete / ready / shipped / committed / fixed / finished / landed* must end with both blocks. The visible part is a blockquote with a glyph heading; the mechanical detection rides on an invisible HTML-comment line above each blockquote.

    <!-- verified -->
    > **✓ Verified**
    > - Pester: GitEasy.savework.tests.ps1 — 14/14 passed (Invoke-Pester run at 2026-05-13T08:14)
    > - Dogfood: ran Save-Work on C:\Sysadmin\Scripts\GitEasy, observed expected commit

    <!-- not-verified -->
    > **⚠ Not verified**
    > - PS 5.1 compatibility — only ran on PS 7.5
    > - Behavior when $env:GITEASY_LOG_PATH is unwritable

Empty bullets are allowed; the HTML-comment markers are not optional. The Stop hook keys on the comment markers (case-insensitive `<!-- verified -->` / `<!-- not-verified -->`, whitespace-tolerant) — invisible in the rendered Markdown so the receipt stays clean. Marker presence ≠ honest content — the hook detects shape only. Honesty of what goes inside the blockquote is on the agent.

Legacy `<verified>...</verified>` tags from the rule's first day are still accepted by the hook so old transcripts pass; new turns use the blockquote form.

## Rule 5 — Sub-agent prompts must carry the no-fabrication preamble

Sub-agents do not read parent skills or memories. When spawning one via the Agent tool, the prompt must contain this preamble:

> **Honesty rule:** do not fabricate paths, APIs, results, or capabilities. Do not weaken assertions to pass checks. Inspection is not verification — cite the test ID, command + exit code, or file read that produced any "verified / tested / works" claim. If validation fails after one fix attempt, stop and report. State what was not verified.

The PreToolUse Agent hook (`sub-agent-honesty-injection.ps1`) enforces this mechanically — any Agent prompt missing the keyword *fabricate* is blocked with the preamble as paste-ready text.

## Common failure modes this skill blocks

- **"The function returns without erroring, so it must work."** Not verification. Cite the test that exercises behavior, or stamp the function `# STUB:` until tests exist.
- **"I ran the tests, they passed."** Not a citation. Name the test, or quote the runner output.
- **"Looks correct."** Inspection, not verification. Either run the verification command or mark the claim `<not-verified>`.
- **"Should handle nulls."** Speculation. Either prove it with a test or call it out as untested.
- **"The migration succeeded."** Said by a sibling agent / dispatch / overnight loop — see `verify-claims-on-disk` for the consumer-side check.
- **Background-agent reports with confident summaries and zero tool calls.** The summary is from the agent's *plan*, not from observed execution. Demand citations or treat the summary as unverified.

## What this skill does NOT replace

- **Disclosure framing in surface docs** (wiki, README, READINESS.md confidence columns) → see `feedback_disclose_half_baked` memory in the meta-Claude.
- **Review cadence between milestones** → see `feedback_milestone_reviews` memory.
- **Verification of OTHER agents' claims** → see `verify-claims-on-disk` skill. This skill is the producer side; that one is the consumer side. Together they close the trust loop.
