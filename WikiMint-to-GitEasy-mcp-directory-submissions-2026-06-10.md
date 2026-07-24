# WikiMint → GitEasy: MCP Directory Submissions

**Date:** 2026-06-10
**From:** WikiMint/Meta Claude

---

## Submitted today

### mcp.so
- **Status:** Submitted ✅
- **Name:** GitEasy MCP
- **Description:** When your AI runs git through a shell, it reads back raw command output — hundreds of tokens of noise to extract one piece of information. GitEasy MCP returns structured data: branch names, changed files, commit history — exactly what your AI needs, nothing extra. The same git operation at a fraction of the token cost. 21 tools, plain English, zero shell parsing.
- **Short description (registry):** `Git via MCP. Structured results instead of raw shell output — fewer tokens per operation.`
- **URL submitted:** https://github.com/greenmtnsun/GitEasy
- **Logo URL used:** https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/site/images/logo.png
- **Tags:** git, version-control, developer-tools, powershell, mcp

### Official MCP Registry
- **Status:** Already live ✅ (`io.github.greenmtnsun/giteasy` v1.5.0)

---

## Still to do

- [ ] glama.ai/mcp — paste form, manually reviewed
- [ ] awesome-mcp-servers PR — one line to https://github.com/punkpeye/awesome-mcp-servers

---

## ~~Token-saving angle (use this in all future copy)~~ — SUPERSEDED 2026-07-23, see below

The core value prop for GitEasy MCP is token savings:
- Raw shell git output = hundreds of tokens of noise per operation
- GitEasy MCP = structured results, only what the AI needs
- Same operation, fraction of the cost

Lead with this in all marketing copy, not the "21 tools" or "plain English" features.

---

## CORRECTION 2026-07-23: do NOT lead with token savings

A measured benchmark (GitEasy-internal `tools/token-savings-test/`, committed
2026-07-23) contradicts the claim above: GitEasy MCP only edges out *naive
default* git output on *large* repos, and loses to terse git flags overall.
Per the anti-vibe rule, the "fraction of the token cost" claim must not appear
in any future directory copy, and the live mcp.so listing (which uses it)
should be edited when Keith next touches that form.

**Replacement angle — lead with structured results + plain English:**

- **Long description:** When your AI runs git through a shell, it has to parse
  raw command output. GitEasy MCP returns structured data — branch names,
  changed files, commit history — in a predictable shape every time. 22 tools,
  plain English, zero shell parsing.
- **Short description (registry):** `Git via MCP. Structured, predictable
  results instead of raw shell output — no git jargon.`

Also corrected: the tool count is **22**, not 21 (verified against
Program.cs tool registration and Glama's introspection).
