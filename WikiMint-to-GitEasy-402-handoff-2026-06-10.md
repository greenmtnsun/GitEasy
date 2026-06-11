# WikiMint → GitEasy: Wire 402 Payment Protocol

**Date:** 2026-06-10
**From:** Meta/WikiMint Claude
**To:** GitEasy Claude
**Priority:** Urgent — someone is actively calling GitEasy on the 402 protocol now

---

## What's needed

Wire HTTP 402 (Payment Required) payment flow into the GitEasy MCP server.

## Key context

- Keith has working C# 402 implementation code already written (done on personal time, not day-job derived)
- He needs to share the code with you — ask him to paste or point you to it before starting
- WikiMint is NOT getting 402 yet — GitEasy is the trial; WikiMint will follow if this goes well

## What 402 means here

When an unauthenticated or unpaid caller hits the GitEasy MCP endpoint, instead of returning 401/403, return HTTP 402 with a payment/upgrade URL so the client can self-serve a key automatically. This is the emerging standard for pay-per-use MCP servers.

## Starting point

- GitEasy MCP lives at `https://giteasy-mcp.azurewebsites.net/mcp`
- Current auth: `X-Api-Key` header check
- Keith's C# 402 code is the implementation — get it from him before touching anything

## First step

Ask Keith to share the 402 C# code, then design the integration before writing any code.
