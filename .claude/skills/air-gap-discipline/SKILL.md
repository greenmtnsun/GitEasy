---
name: air-gap-discipline
description: Use when authoring or modifying any code under C:\Sysadmin\Scripts\. Encodes the air-gap philosophy — code does not know its environment, never leaks machine names / domain prefixes / IPv4 addresses, and is portable across work / CI / personal contexts. Pairs with the air-gap-sentinel PreToolUse hook which blocks the most common leakage patterns automatically.
---

> See also: `software-creation` for the broader discipline. `module-suite` for cross-product strategy. The `air-gap-sentinel` hook (in `~/.claude/settings.json`) is the safety net.

# Air-gap discipline

Suite source ships across multiple environments — Keith's personal machine, CI runners, future enterprise customers, eventually paid distribution. **Code does not know which environment it is in.** That single rule drives the rest.

## The three rules

### 1. Environment blindness

Code does not test for environment. No `if ($env:COMPUTERNAME -eq 'KEITHWORK')`. No "if I am on the build server, do X." Configuration that varies by environment lives in:

- the user `$PROFILE` (per-user override)
- the configuration registry (per-module — see ModuleWorkshop DR-011)
- explicit parameters at invocation

If a function genuinely needs to behave differently in two environments, that behavior is a parameter, not an `$env:` check.

### 2. Zero metadata leakage

The following do not appear in source files:

- Machine names (`KEITHWORK01`, `BUILDSRV02`, anything that names a real host)
- Domain prefixes (`WORKDOMAIN\username`, `\\WORKDOMAIN\share`)
- IPv4 addresses outside loopback (`127.x.x.x`), the reserved `0.0.0.0/8` block (RFC 1122), the limited broadcast `255.255.255.255`, link-local (`169.254.x.x`), or the RFC 5737 documentation ranges (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`)
- Internal URLs that name a specific organization
- Service-account names tied to one environment
- UNC paths beyond placeholders

When example data is needed, use generic placeholders: `\\SERVER01\share`, `192.0.2.1` (TEST-NET-1, RFC 5737 — explicitly reserved for documentation), `example.com`, `user@example.com`.

### 3. Standalone integrity

Each module is independently runnable. No cross-module imports of code; integration goes through the JSON schema (see `module-suite` skill). Modules share *patterns* (DNA), not *code*.

## When this skill triggers

- New file or edit under `C:\Sysadmin\Scripts\`
- Code review of a module being prepared for distribution
- Schema or rendering changes that may surface environment-specific data
- Pre-release audit (pairs with `release-audit` once that skill lands)

## What it does at trigger

1. Check the change against the three rules. If a leak slips through, name the rule and propose the placeholder substitution.
2. When a value would naturally be environment-specific (server, port, file path), check whether it should be a parameter, a registered config setting, or a placeholder example.
3. When tempted to write `if ($env:USERDOMAIN -eq ...)`, stop and propose a configuration-driven alternative.

## What it does NOT do

- Does not apply to one-off scripts outside `C:\Sysadmin\Scripts\`.
- Relaxes for test fixtures clearly labeled as such (under `Tests/Fixtures/`). Fixtures may need to mock specific values; the air-gap-sentinel hook will not flag them when scoped there.
- Does not apply to comments quoting real-world examples for documentation, but the hook may flag them anyway. When that happens, switch to a placeholder (`192.0.2.1`) — the example reads the same and the hook stops complaining.

## The hook backing this skill

`air-gap-sentinel` (PreToolUse, on Edit and Write) blocks any save to `.ps1`/`.psm1`/`.psd1` under `C:\Sysadmin\Scripts\` that contains UNC paths with named hosts or non-loopback IPv4 **or IPv6** addresses outside the documentation ranges (IPv6 detection added to the hook 2026-05-07; this description caught up 2026-08-15). The skill is the deliberate layer; the hook is the structural safety net. If the hook fires on legitimate content, the right response is to switch to placeholders, not to disable the hook.
