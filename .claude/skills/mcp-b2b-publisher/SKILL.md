---
name: mcp-b2b-publisher
description: >
  B2B compliance enforcement for MCP tool servers intended for commercial sale.
  Apply whenever generating, reviewing, or auditing MCP tool definitions, auth
  config, billing, versioning, observability, docs, or marketplace assets in
  any project. Enforces 10 DO rules (HARD) + 10 DONT anti-patterns (HARD/ADVISORY).
version: 1.0.0
last-updated: 2026-06-03
triggers:
  - writing or reviewing an MCP tool definition
  - reviewing tool descriptions, parameter names, or output schemas
  - designing auth, billing, or metering for an MCP server
  - preparing a marketplace listing or GA checklist
  - any PR touching tool definitions in WikiMint or FullOfWikis Agent
---

# MCP B2B Publisher Compliance Skill

When invoked, load and enforce the full rule sets from:
- `C:\Sysadmin\Scripts\WikiEngine\.claude\MCP_B2B_PUBLISHER.md` (10 DO rules)
- `C:\Sysadmin\Scripts\WikiEngine\.claude\MCP_B2B_PUBLISHER_DONTS.md` (10 DONT rules)

If those files are not in the active project, fall back to the embedded rules below.

---

## Quick-reference enforcement (embedded)

### HARD DO rules — stop and flag before producing output

| Rule | Requirement |
|------|-------------|
| 01 | Every tool has a `pain_statement` naming role + measurable cost |
| 02 | Description ≤60 words total; first sentence ≤25 words; no "helps", "enables", "leverages" |
| 03 | `outputSchema` fully typed; `status: "success"\|"partial"\|"error"`; error includes `{ code, message, retryable }` |
| 04 | OAuth 2.1 / RFC 8707; no tokens in tool results; scopes per-tool |
| 05 | Each tool carries its own SemVer `version` field; MAJOR bump on breaking changes |
| 06 | Every invocation emits metering event with `tenant_id`, `invocation_id`, `billable_units` |
| 07 | GA requires marketplace listing with pain statement, pricing, auth, example I/O |
| 08 | `X-RateLimit-*` headers on every response; soft-limit warning at <20% remaining |
| 09 | Structured JSON logs with `invocation_id` correlation; no credentials or PII |

### ADVISORY DO rule

| Rule | Requirement |
|------|-------------|
| 10 | Freemium tier sized to prove ROI; free responses include `_meta: { tier, calls_remaining, upgrade_url }` |

### HARD DONT rules — stop and flag before producing output

| Rule | Anti-pattern |
|------|-------------|
| 01 | No god-tools with `mode`/`action`/`type` branching; one tool = one focused contract |
| 02 | Auth trust boundary decided and documented before GA; no "auth is phase 2" |
| 03 | Tool names follow `verb_specificNoun`; no `get_data`, `process`, `execute`, `run` |
| 04 | Destructive tools (write/delete/send/pay) require audit gate + `action_id` in response |
| 05 | No bare `object` parameters; no `options`/`config`/`payload` blobs; all properties typed inline |
| 07 | Common workflows complete in ≤2 tool calls; no mandatory cursor-then-fetch patterns |
| 08 | Errors use taxonomy prefixes: `AUTH_`, `VALIDATION_`, `NOT_FOUND_`, `UPSTREAM_`, `INTERNAL_`; `retryable` always present |
| 10 | Every tool tested by watching an actual agent use it before GA — unit tests alone are not sufficient |

### ADVISORY DONT rules

| Rule | Advisory |
|------|---------|
| 06 | Tool descriptions reviewed by someone fluent in the buyer's workflow language, not the codebase |
| 09 | MCP is not a REST reshell; hide pagination, abstract filter DSLs, expose business concepts |

---

## Per-tool, per-PR checklist

Run both checklists before any tool-related merge:

```
DO  01 — Pain statement: role + cost named?                            [ ]
DO  02 — Description ≤60 words, no vague verbs, template format?       [ ]
DO  03 — outputSchema typed; status/error envelope with retryable?     [ ]
DO  04 — OAuth 2.1 / RFC 8707; no token leaks?                        [ ]
DO  05 — Per-tool version field; changelog updated?                    [ ]
DO  06 — Metering event emitted on every code path?                    [ ]
DO  07 — Marketplace listing created or updated?                       [ ]
DO  08 — Rate limit headers + soft-limit warning present?              [ ]
DO  09 — Structured JSON logs with invocation_id, no PII?              [ ]
DO  10 — Free tier upgrade hint in response? (advisory)                [ ]

DONT 01 — No god-tools; no mode/action branching?                      [ ]
DONT 02 — Auth trust boundary locked before GA?                        [ ]
DONT 03 — All tool names follow verb_specificNoun?                     [ ]
DONT 04 — Destructive tools have audit gate + action_id?               [ ]
DONT 05 — No omnibus blob parameters; all properties typed inline?     [ ]
DONT 06 — Domain-fluent description review done? (advisory)            [ ]
DONT 07 — Common workflows complete in ≤2 tool calls?                  [ ]
DONT 08 — Error taxonomy with retryable field on all paths?            [ ]
DONT 09 — Not a REST reshell; business concepts exposed? (advisory)    [ ]
DONT 10 — Agent-usability test passed (not just unit test)?            [ ]
```

---

## How to use this skill

When invoked explicitly (`/mcp-b2b-publisher`) or triggered by work on tool definitions:

1. Read the full rule files from `.claude/` if available.
2. Scan the work against all HARD rules before producing output.
3. State violations as blockers — never soften a HARD rule with "you might want to consider."
4. Surface ADVISORY rules as recommendations.
5. Produce a compliance report using the checklist above when reviewing existing code.
6. Never approve GA-ready status unless DONT 10 agent-usability test is explicitly confirmed.

## WikiMint-specific open compliance gaps (as of 2026-06-03)

WM-100 through WM-113 in `WikiMint/GOALS.md` track the identified violations.
The highest-priority OPEN items before first customer contact:
- WM-100: Fix status envelope (`"success"/"partial"/"error"` + `retryable`)
- WM-103: Error code taxonomy
- WM-104: Agent-usability test (DONT 10)
- WM-105/106: Pain statements + description audit
