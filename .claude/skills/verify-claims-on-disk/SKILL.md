---
name: verify-claims-on-disk
description: Use when a sibling Claude session, handoff doc, scheduled task, or background process claims a change was applied ("I added X", "applied the fix", "wrote Foo to bar.ps1", "commit 1 landed", "Phase 3 complete"). Verify the change actually landed on disk before building on the assumption. Two real incidents in 7 days (2026-05-06 dispatch claimed 3 fixes that didn't apply; 2026-05-08 overnight scheduled fixes sat on permission prompts and shipped 0 of 6) justify treating apply-claims as untrusted by default. Quick to verify (one Read or Grep), expensive to trust falsely (hours of misplanning on a false premise).
---

> See also: `software-creation` §4 for the structured-result discipline that makes apply-claims inspectable in the first place.

# Verify-claims-on-disk

When *another* session, handoff doc, or background process tells the current session that something was applied, **verify before building on it.** Apply-claims have failed twice in the last 7 days; treat them as proposals until disk confirms.

The current session's own recent edits are different — those have tool-result evidence in the same conversation. This skill is about **trans-session trust.**

**Mechanized path (prefer this):** if the handoff doc carries a `## Claims` block (see the `handoff` skill), run `Test-HandoffClaims.ps1 -HandoffPath <doc>` from this skill's folder instead of hand-verifying — exit 0 = all claims match disk, exit 1 = drift, do not build on the handoff. The manual protocol below remains for claims made outside a handoff doc (chat messages, dispatch output, docs without a Claims block).

## Trigger phrases

This skill activates when the conversation contains any of:

- *"I applied X"* / *"applied the [fix | change | edit]"*
- *"I added [function | class | line | comment | test]"*
- *"I removed X"* / *"deleted X"*
- *"wrote [content] to [path]"* / *"saved [path]"*
- *"[file] now contains X"* / *"the change is in [file]"*
- Any handoff doc claiming completed edits (*"commit 1 landed"*, *"Phase X complete"*, *"shipped"*)
- Any apply-claim from a separate Claude session (dispatch-app, phone Claude, scheduled task, overnight loop)
- Any "before/after" comparison where the "after" wasn't observed in the current session

If the conversation includes a phrase like the above and the change isn't visible in the current session's tool history, run the verification protocol.

## Verification protocol

### Step 1 — Parse the claim into three things

| Field | Example |
|---|---|
| File path | `C:\Sysadmin\Scripts\PesterForge\Public\Invoke-PesterForge.ps1` |
| Expected content | `function Invoke-PesterForge` (a symbol) OR a literal line excerpt |
| Operation | `added` / `removed` / `modified` / `created` / `deleted` |

If any of the three is ambiguous, ask the source for clarification before checking. **Don't guess** — guessed verification is worse than no verification (false negatives create false confidence).

### Step 2 — Existence check

```powershell
Test-Path $filePath
```

- `created` claim → file should now exist. If absent → DRIFT.
- `deleted` claim → file should now be absent. If present → DRIFT.
- `added`/`removed`/`modified` → file should still exist. If absent → DRIFT (claim is incoherent).

### Step 3 — Content check

For an **added** claim:

```powershell
Select-String -Path $filePath -Pattern $expectedSymbol -SimpleMatch -Quiet
```

For AST-level checks (function definitions, class declarations), parse the file and walk the AST rather than substring-matching:

```powershell
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$errors)
$funcs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
$funcs.Name -contains $expectedFunctionName
```

For a **removed** claim, invert: assert the symbol is **not** present.

For a **modified** claim, read the relevant section (using line ranges from the claim if available) and compare to the expected new content.

### Step 4 — Report

| Result | Meaning | Next action |
|---|---|---|
| **MATCH** | File state matches the claim | Trust the claim; build on it |
| **DRIFT** | File state differs from claim | Surface the diff; **do NOT build on the claim** until source clarifies |
| **MISSING** | File doesn't exist where claimed | Treat as DRIFT (apply-claim is incoherent) |

A DRIFT report should include:
- The claim, verbatim
- What was checked (path + pattern + operation)
- What was found (file content excerpt or *"not present"*)
- A one-line proposed next step (re-ask the source, re-run the apply, escalate to Keith)

## When NOT to verify

Skip the protocol if any of these is true:

- The current session itself made the change one or two turns ago and the tool result already showed success. Verifying your own recent edits is paranoid; trust the tool harness.
- The claim is about behavior, not file state (*"the test passes now"*) — that's a different verification (run the test, don't grep the file).
- The source is a system reminder confirming a file was modified by user/linter — those reflect actual disk state.
- The claim is about transient runtime state (*"the variable is now set"*) — file-on-disk verification doesn't apply.

## Common failure modes the protocol catches

- **Worktree discarded.** A sibling session worked in a temporary git worktree (e.g., `--isolation worktree` agent run) that was cleaned up after the agent finished without merging. The claim is true within the worktree, false on the persistent tree.
- **Permission prompt blocked.** A scheduled task or autonomous loop hit a permission prompt nobody answered. The claim was generated *before* the prompt fired (planning step succeeded), but the actual write was rejected.
- **Cache vs disk.** The source's view of the file was cached (e.g., from a tool-result earlier in *its* conversation) while another agent has since modified or reverted it.
- **Wrong path.** The claim names a file path that resolves differently in two contexts — relative paths in two project roots, or `~/` expansion in two user contexts.
- **Confident hallucination.** The claim describes a logical change that was *planned* but never *executed* — the source's planning step ran but the action step didn't.
- **Optimistic apply.** The source ran an Edit/Write that returned success, but a PreToolUse hook subsequently blocked the actual disk write. (Some harnesses treat hook-blocked edits as silent no-ops in the tool result.)

## Red flags worth questioning before any verification

- **Vague claims** without specific file:symbol pairs (*"I made the changes,"* *"everything's set up,"* *"the work is done"*).
- **Multi-step apply claims with no intermediate evidence** (*"ran 6 fix iterations overnight"*, *"applied 12 patches in sequence"* — high prior probability of partial failure).
- **End-of-long-autonomous-run claims** without prior tool-result evidence in the conversation history.
- **Dispatch / handoff docs over 24 hours old** — disk state may have moved since the doc was written.

## Cost framing

- **Cost of running the protocol:** one `Test-Path` + one `Select-String` (or AST parse). ~1 second of work, two tool calls.
- **Cost of skipping it and trusting a false claim:** hours of work built on a false premise, plus the time to discover and unwind it. Both 7-day incidents cost more than 30 minutes of misplanning each.

When in doubt, verify. The asymmetry pays for itself.
