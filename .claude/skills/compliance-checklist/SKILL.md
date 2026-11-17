---
name: compliance-checklist
description: Use when authoring or modifying a public cmdlet in any of Keith's suite projects. Walks the relevant sections of SUITE-PR-GATE.md (the canonical PR-merge gate) and surfaces the items the cmdlet must satisfy before it's PR-ready. Auto-triggers on new function authoring (paired with function-design); also invocable directly when reviewing or hardening an existing cmdlet. Distinct from virtual-security-reviewer (adversarial review) — this skill is the operator-side checklist.
---

> See also: `feedback_suite_security_bar` memory for the why + three-phase adoption plan. `function-design` for the parameter/pipeline/output contract. `software-creation` §4 for the structured-result-with-CategoryInfo+TargetObject rule. `virtual-security-reviewer` for adversarial review when the cmdlet handles untrusted input or credentials.

# Compliance Checklist — operator-side PR gate

The canonical content lives in `C:\Users\keith\.claude\cross-project-artifacts\SUITE-PR-GATE.md`. This skill is the operational layer that surfaces the right sections at the right time, in plain English, when a cmdlet is being authored or modified.

## When this skill triggers

- A new function is being created in any `Public/` folder under `C:\Sysadmin\Scripts\`.
- An existing public cmdlet is being modified in a way that changes parameters, error paths, or credential handling.
- Keith says "PR-gate this", "compliance-check", "is this ready to merge", "walk the checklist".
- Before declaring a Phase transition in any project (per `phase-gate` skill) — the closing phase's cmdlets get walked.

## How to use it

The skill walks the checklist by **section relevance**, not by reading the whole doc. For each cmdlet under review, pick the sections that apply:

| Section | Applies when | Cmdlets where this bites |
|---|---|---|
| **A. Input handling** | Any cmdlet with parameters | All |
| **B. T-SQL composition** | Cmdlet builds T-SQL | SqlBackupValidation, SqlSpnManager, eventual IDKSqlServer2025 only |
| **C. Credential handling** | Cmdlet accepts or produces secrets | Set-Token, Set-Ssh, Set-Vault (GitEasy); any cmdlet returning a connection |
| **D. Transport security** | Cmdlet opens network connections | Get-Updates, Save-Work (GitEasy); WikiEngine REST; PesterForge Anthropic calls |
| **E. Process / shell invocation** | Cmdlet runs external commands | Invoke-GEGit (GitEasy); ClusterValidator's CIM/WMI shellouts; PhotoOrganizer Python bridge |
| **F. Privilege** | Cmdlet performs surprising or privileged actions | All `Set-` / `New-` / `Remove-` |
| **G. Error handling and info disclosure** | All cmdlets | All |
| **H. Idempotency and state** | `Set-`/`Enable-`/`Disable-`/`New-`/anything that writes | All write-side cmdlets |
| **I. Resource bounds** | Cmdlet opens a connection, makes an HTTP call, or polls | All network-touching cmdlets |
| **J. Audit** | State-changing cmdlet | All `Set-`/`New-`/`Remove-`/`Enable-`/`Disable-` |
| **K. Tests** | All | All |
| **L. Documentation** | All public cmdlets | All public |
| **M. Untrusted JSON/XML deserialization** (CWE-502 gap section) | Cmdlet calls `ConvertFrom-Json` / `Import-Clixml` on input that came from a network, file, or another process | PesterForge (Anthropic responses), WikiEngine (Confluence REST), any cmdlet reading user-supplied JSON config |
| **N. Internal-network URL targets** (CWE-918 gap section) | Cmdlet accepts a URL parameter and fetches it | Any cmdlet that takes a `-Url` / `-Endpoint` / `-Uri` and calls `Invoke-RestMethod` / `Invoke-WebRequest` |

## What this skill does NOT do

- **Doesn't grade.** Section X is met or not met; no "85% PR-ready" score.
- **Doesn't substitute for the security reviewer.** When the cmdlet touches untrusted input, credentials, or external systems, also invoke `virtual-security-reviewer` for adversarial review.
- **Doesn't auto-fix.** This is a walking-the-checklist skill, not a refactor skill. When an item fails, the skill names what's missing; the author fixes it.
- **Doesn't rubber-stamp.** If an item can't be filled in honestly, say so explicitly rather than claiming "checked." The whole point of the gate is to prevent silent skipping.

## Tools/ scripts that ship with the module

This skill is scoped to public cmdlets, but a project's `Tools/` scripts
(signing, install, scaffold) also need security review when they touch the
filesystem, the certificate store, or scheduled-task surface. The 2026-05-13
suite security sweep catalogued eight patterns; two land here:

- **P-4 (Signing-tool ProjectRoot guard)** — `Tools/Set-*AuthenticodeSignature.ps1`.
  See `software-creation` §12a for the fix shape (manifest check before walking
  files). Reference commit `baa6f4a` on ClusterValidator.
- **P-7 (CmdExec command-line injection)** — `Tools/Install-*Job.ps1` /
  `Tools/Install-*Task.ps1`. Reject shell metacharacters in path-shaped args
  before building the command line. Reference handoff
  `cross-project-artifacts/handoff-2026-05-13-cwe-sweep.md`.

When PR-gating a change that touches a `Tools/` script of one of these shapes,
walk the relevant pattern before merge.

## Three planned-but-NOT-built items (CHECK THESE BY EYE — corrected 2026-08-15)

**These three were described as mechanized, but none exist on disk** (verified 2026-08-15: no `~/.claude/pssa-rules/` directory, no `weak-crypto-guard.ps1` in hooks or settings.json — the only copy is an undeployed 5/9 proposal). Sessions were skipping checks nothing was performing. Until they're built, walk them MANUALLY on every cmdlet:

1. **Secret-string parameters** — flag `[string]$Password`/`[string]$Token`/etc. by eye; sensitive parameters must be `[SecureString]`/`[PSCredential]`.
2. **Weak crypto** — flag any new MD5/SHA1 constructor in `.ps1`/`.psm1` used for security purposes.
3. **Unpinned RequiredModules** — flag bare-string `RequiredModules` entries in `.psd1` manifests lacking version pins.

(The original mechanization designs are preserved in `feedback_suite_security_bar` §5 for whenever they get built.)

## Three-phase reminder

`feedback_suite_security_bar` memory tracks the staged adoption. **Phase 1 (now)** items are non-negotiable for new cmdlets. Phase 2 + Phase 3 items wait for trigger events (first paying customer, first regulated buyer). Don't apply Phase 3 ceremony to Phase 1 code.

## Output shape when this skill runs

A short PR-gate report:
- Sections walked: <list>
- Sections N/A and why: <list>
- Items missing: <list with file:line if applicable>
- Mechanized checks status: <PSSA + hook results>
- Phase-relevant items beyond Phase 1: <list, marked for later>

Surface the gaps to Keith; let him decide which to fix now vs. defer.
