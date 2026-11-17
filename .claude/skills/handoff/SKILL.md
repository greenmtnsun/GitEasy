---
name: handoff
description: Use when ending a session, pausing multi-day work, or handing work to another session/project — writes a handoff doc with disk-verified claims and a machine-checkable Claims block. Triggers on "write a handoff", "hand this off", "wrap up for the day", session-end with unfinished work. Also use when a handoff doc is pasted or pointed to, or a session is resumed from one: the receiving session does the work.
---

# Handoff

Write a handoff doc prefixed with the source project name. Include: state on disk, verified test counts, open items, and pickup location. Verify all claims against disk before writing.

## Rules

- Filename must start with the source project name: `<ProjectName>-<topic>-<YYYY-MM-DD>.md` (per CLAUDE.md §8 — that's the canonical home of the naming rule)
- Every claim about test counts, commit SHAs, or file contents must be verified on disk before writing — no guessing
- Include these sections:
  - **State on disk** — what was built, what was committed, what is only written but not committed
  - **Verified test counts** — exact pass/fail/skip counts from the last Pester run (cite the run, not memory)
  - **Open items** — what is unfinished, blocked, or DR-gated; be explicit about what needs a DR vs. what can proceed
  - **Pickup location** — exact path(s) the next session needs to open; the exact command to resume
  - **Claims** — a machine-checkable `## Claims` block: one `- file: <path>  contains: <literal>` line per apply-claim (also supports `pattern: <regex>`, `absent: <literal>`, or bare `file:` for existence). The consuming session verifies with `skills\verify-claims-on-disk\Test-HandoffClaims.ps1 -HandoffPath <doc>` — exit 0 = safe to build on, exit 1 = do NOT build on this handoff
- Drop the file in the appropriate location:
  - Cross-project handoffs → `C:\Users\keith\.claude\cross-project-artifacts\`
  - Per-project handoffs → `<ProjectRoot>\.claude\`
- Never overwrite an existing handoff — append a datestamp or increment if one already exists

## Receiving a handoff

- A handoff pasted into or pointed at this session is this session's work. Don't treat it as addressed to another Claude, and don't hand it back.
- Run the Claims check first (`Test-HandoffClaims.ps1`). Exit 1 means verify the failing claims before building on them.
- Then start the top unblocked open item. A survey of the repo is not a resume. Stop only at a named blocker, a §7 gate (publish, deploy, destructive), or when Keith asked for a report only.
