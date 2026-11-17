---
name: verify
description: Use before every commit, before any claim that work is done, tested, fixed or working, when Keith asks "does it work" or "is this ready", when a repo has no .claude/skills/verify yet, or when asked to smoke-test, verify, or prove a change. The contract for each repo's own verify skill (its smoke-test harness), the order checks run in, the diff-triggered pattern checklist, the two-attempt stop rule, the flaky-test rule, and the Verified: commit trailer the commit-verify-gate hook reads. Adopted 2026-11-17 from the Claude Code team's verification practice. Pairs with honest-completion (the reply closeout), commit-verify-gate (the commit stamp) and review-loop (REVIEW.md).
---

> See also: `honest-completion` for the closeout a reply must carry, `verify-claims-on-disk` for checking another session's claims, `release-qa-passes` for release-cadence passes, `review-loop` for the review that runs after verification. The built-in `run` skill is the fallback launcher when a repo has no verify skill yet.

# Verify

Verification means running the change, not reading it. Keith adopted the Claude Code team's
practice on 2026-11-17: every repo carries a `verify` skill that boots the product, drives one real
flow and inspects the result; Claude runs it before every commit; the commit says how it was checked.
With that in place the human's job moves from reading every diff to defining what done looks like and
reading the evidence.

## Where it lives

| What | Where |
|---|---|
| The contract (this file) | `C:\Users\keith\.claude\skills\verify\SKILL.md` |
| The template for a repo's own skill | `C:\Users\keith\.claude\skills\verify\TEMPLATE-verify-SKILL.md` |
| The diff-triggered checklist | `C:\Users\keith\.claude\skills\verify\Get-DiffTriggeredChecks.ps1` |
| A repo's own verify skill | `<repo>\.claude\skills\verify\SKILL.md`, as close to the code as it can be |
| The commit gate | `C:\Users\keith\.claude\hooks\commit-verify-gate.ps1`, mode in `commit-verify-gate.mode` |

## The procedure, every time

1. **Find the repo's verify skill.** Read `<repo>\.claude\skills\verify\SKILL.md`. If there is none,
   author one now from the template, in the same commit as the work. A missing harness is a work
   item, not a reason to skip (CLAUDE.md section 14). Until it exists, the built-in `run` skill
   launches the app.
2. **Cheap checks first.** Static analysis, build, unit tests, in that order, from the directory the
   repo's skill names. Stop at the first failure and fix it before anything slower runs.
3. **Run the repo's smoke test.** Boot the product the way the skill says, drive the one real flow it
   names, inspect what it says to inspect. For a PowerShell module that is import, run
   `Tools\Invoke-*Pester.ps1`, then run one public command against a real target. For a UI it is the
   UI gate with a screenshot. For a service it is a real request to the real path with the status
   code shown.
4. **Run the diff-triggered checklist.** From the repo root:

   ```
   pwsh -NoProfile -File C:\Users\keith\.claude\skills\verify\Get-DiffTriggeredChecks.ps1 -RepoPath .
   ```

   It reads the staged diff and prints each pattern-library entry whose `trigger:` matches. Read
   each matched pattern and apply it. Most diffs match none; a diff that matches one gets that
   check and no more. Success check: the script prints a count line and exits 0.
5. **A failing check gets one fix and one retry.** If the second attempt fails too, stop and bring
   it to Keith in the question window with the output (CLAUDE.md section 18, honest-completion
   rule 3). The Claude Code team stops at three rounds. The house rule is two.
6. **Flaky tests.** Never skip one, add a sleep, or re-run it until it passes. Find the root cause.
   If the cause cannot be found, delete the test and say why in the commit message. Note the
   deletion under Not verified in the closeout.
7. **Stamp the commit.** End the commit message with a `Verified:` trailer. The commit-verify-gate
   hook reads it. Then write the reply's closeout per honest-completion.

## The Verified: trailer

One line at the end of the commit message body. It names what ran and what it showed.

```
Verified: Pester 14/14 (GitEasy.savework.tests.ps1); verify skill ran Save-Work on a scratch repo and saw the commit
Verified: dotnet build exit 0, 0 errors; xUnit 444/444; GET /health on the dev slot returned 200 with v0.4.1
Verified: none - docs-only change, no code path touched
```

`none` is allowed. It needs a reason after it. A bare `Verified: none` is treated as no trailer.
Unverified commits can then be found later with `git log --grep='Verified: none'`.

The gate has three modes, set in `commit-verify-gate.mode`:

- `off`: nothing happens.
- `observe` (the starting mode): a commit without a trailer passes, is logged to
  `commit-verify-gate.log` as would-block, and Claude is told. Read the log for false positives
  before moving on.
- `enforce`: a commit without a trailer is blocked. After two blocks in one session the third
  commit passes and is logged, so a session never wedges.

Moving the mode is Keith's call. The log is the evidence for it.

## What does not count as verification

- Reading the code and reasoning about it. That is review. Call it reviewed.
- "Tests pass" with no test name, count or runner output.
- A green mocked suite at an external boundary (the `mocked_green_not_proof_at_external_boundary`
  pattern). Name which layer ran.
- A unit suite standing in for a flow the user would drive (the
  `narrow_gate_green_not_proof_of_broad_claim` pattern).
- A sibling session's claim that something ran. That is `verify-claims-on-disk`.

## Authoring a repo's verify skill

Copy the template to `<repo>\.claude\skills\verify\SKILL.md` and fill every section. Rules:

- Name the directory each command runs from and the success check Keith should see (CLAUDE.md
  section 9).
- One real flow, end to end, that a user would recognise. Not a unit test.
- Make it fast and reliable. The Claude Code team calls it the smoke test harness and has Claude
  iterate on it and stress-test it. A slow or flaky harness trains the agent to skip it.
- Say what the harness does not prove, so the Not verified block can be written from it.
- Keep it current. When the way the app boots changes, the skill changes in the same commit.

## Tests worth adding when the harness is thin

From the Claude Code team's list, in the order they pay off here:

- **End-to-end** first. A test that drives the real flow gives a step trace and a screenshot when it
  fails, where a unit test gives a timeout.
- **Property tests** for anything with a ConvertTo and ConvertFrom pair (round trip), every Set-
  cmdlet (idempotency: twice equals once), and any rewrite of working code (new equals old on
  generated inputs). C# repos can use FsCheck. PowerShell has no mainstream library; a short
  generator loop inside Pester is the realistic form.
- **Differential tests** for migrations: run old and new on the same sampled inputs, normalise
  whitespace, keep an approved-differences list, and investigate the rest.

Heavier tests belong before a commit, not in every loop iteration.
