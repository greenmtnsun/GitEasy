---
name: software-creation
description: Apply Keith's software-creation discipline when authoring or modifying code in his PowerShell projects (PesterForge, GitEasy, ClusterValidator, WikiEngine, or new modules in the same style) — atomic scripts, structured result objects (never throw), change-log header standard, plain-English public surface, decision-record workflow, phase-gated development, four-tier confidence model. Triggers on new function/file creation, file edits, architectural decisions, and DR-eligible design choices. Distinct from module-suite, which covers cross-product strategy.
---

> See also: `module-suite` for cross-product strategy.

# Keith's Software-Creation Discipline

This is the operating manual for software work in Keith Ramsey's project root
(`C:\Sysadmin\Scripts\`). It is opinionated and consistent across every project
he ships: the Module Suite (PesterForge, GitEasy, WikiEngine, ModuleWorkshop —
coordinated by the `module-suite` skill) plus other PowerShell modules at the
root (ClusterValidator, dbaReplication, DBCCProject/SqlBackupValidation,
SqlSpnManager, SQLMonitorBackups, SqlTechnicalSanity, PhotoOrganizer — same
discipline, suite-membership status varies). Apply these rules without
restating them to him each time — he has already accepted them.

If a request would violate one of these rules, push back before doing it.

---

## 1. Atomic Scripts Only

Every script is atomic:

- One file does one clear task
- Complete and runnable on its own
- No dependence on hidden context (no inherited `$PSScriptRoot`, no required parent state)
- Accepts explicit parameters with documented defaults
- Performs a state check before making changes
- Reports exactly what it changed
- Can be tested independently with Pester

Multi-purpose scripts only exist when the file is explicitly an orchestrator
(e.g., `Invoke-PesterForge` orchestrating the AST + generation pipeline).
Helper functions in the same file as the public function are a violation
unless the helpers are unmistakably internal scaffolding.

---

## 2. No `$PSScriptRoot` in Business Code

`$PSScriptRoot` is only permitted in `*.psm1` module loaders. Everywhere else,
use an explicit `-ProjectRoot` parameter with a hardcoded default:

```powershell
param(
    [string]$ProjectRoot = 'C:\Sysadmin\Scripts\PROJECTNAME'
)
```

The state checker (`Test-PfProjectState.ps1` and equivalents) actively scans
for `$PSScriptRoot` in business code and reports it as a violation.

---

## 3. Change Log Header on Every File

Every `.ps1`, `.psm1`, and `.psd1` file begins with this exact header. New files
get one entry; modified files get a new dated entry appended.

```powershell
# =============================================================================
# Script  : FileName.ps1
# Author  : Keith Ramsey
# Created : YYYY-MM-DD
# =============================================================================
# Change Log
# -----------------------------------------------------------------------------
# YYYY-MM-DD  Keith Ramsey  Initial creation
# YYYY-MM-DD  Keith Ramsey  <plain-English summary of what changed and why>
# =============================================================================
```

Comment-based help (`.SYNOPSIS`, `.PARAMETER`, etc.) goes inside the function,
after the header. Keep change log entries short (≤80 chars) and concrete —
"Phase 2: writes generated content to disk" is good; "Updates" is not.

---

## 4. Structured Result Objects, Never Throw

Functions never throw unhandled exceptions. They always return a `PSCustomObject`
with at least `Status`, `Outcome`, and `ErrorCategory`.

**Scope (clarified 2026-08-15):** the never-throw rule governs MODULE functions
(Public/ and Private/). Operator scripts in `Tools/` may fail fast with `throw`
as a deliberate guard — §12a's mandated signing-tool guard is the pattern, not a
violation of this section.

```powershell
return [PSCustomObject]@{
    Status        = 'Succeeded' | 'HandledError' | 'MissingPath' | 'UnknownCategory'
    Outcome       = '<plain-English description>'
    ErrorCategory = 'None' | 'HandledError' | <project-specific category>
    # plus function-specific fields
}
```

A function with multiple result paths still returns a result on every path.
The `try { ... } catch { return [PSCustomObject]@{ Status='HandledError'; ... } }`
pattern is the standard.

For functions returning a list of results (e.g., scaffold creation, project state
check), each list element is a structured result; the function may also return a
summary object wrapping the list.

Never silently drop results.

### 4a. HandledError must be SIEM-parsable

Per the suite security bar (`feedback_suite_security_bar.md`), every `HandledError`
result also carries two fields that let a downstream parser (SIEM, log aggregator,
audit pipeline) classify and correlate the failure without parsing message strings:

```powershell
return [PSCustomObject]@{
    Status        = 'HandledError'
    Outcome       = 'Connection refused by sql01.local on port 1433.'
    ErrorCategory = 'ConnectionFailed'    # vocabulary stays project-defined; pick from a closed set per project
    TargetObject  = $ServerInstance       # what was being operated on (the input that triggered the failure)
    # plus function-specific fields
}
```

- **`ErrorCategory`** is the equivalent of `[System.Management.Automation.ErrorCategory]`
  but project-defined. Keep the set closed and small per project — `ConnectionFailed`,
  `PermissionDenied`, `InvalidInput`, `NotFound`, `Timeout`, `Conflict` are typical.
  Free-form strings make SIEM correlation harder.
- **`TargetObject`** is the input that triggered the failure — a path, a server name,
  a request id, a database, an account. Lets a SIEM correlate failures across the
  fleet without parsing `Outcome` prose. Omit only when there is no meaningful target
  (rare).

Why: enterprise buyers' SIEMs ingest your audit feed. A `HandledError` without
classification is opaque; one with `ErrorCategory` + `TargetObject` plus your
existing `Outcome` is structured enough to drive dashboards and alerting without
brittle string parsing.

---

## 5. Plain English in the Public Surface

Public function names, parameter names, error messages, and `Outcome` text use
plain English — not jargon, not internal abbreviations. The engine can be
sophisticated; the public surface stays readable to a sysadmin who has never
seen the code before.

Examples of *wrong*:
- `Invoke-PfPx -Mode 'CI' -Tgt 'X'` — abbreviated, opaque
- `ErrorCategory = 'CSE'` — internal acronym
- `Outcome = "rc=1, fb=skip, abrt"` — log format, not English

Examples of *right*:
- `Invoke-PesterForge -ScriptPath '...' -CiMode`
- `ErrorCategory = 'ConnectionFailed'`
- `Outcome = "Output file already exists. Use -Force to overwrite."`

If a jargon regression slips into the public surface, back it out.

---

## 6. Required Project Structure

Every Keith project follows this layout. Missing folders are flagged by the
project state checker.

```
C:\Sysadmin\Scripts\PROJECTNAME\
├── PROJECTNAME.psd1
├── PROJECTNAME.psm1
├── Public/         (exported functions, one per file)
├── Private/        (internal functions, one per file)
├── Tests/
│   ├── Static/
│   ├── Unit/
│   ├── Integration/
│   └── Acceptance/
├── Docs/
├── Tools/          (operator-facing scripts: state checker, scaffold, runner)
├── Config/
├── Examples/
└── Runbooks/
```

The module manifest (`.psd1`) exports only the functions in `Public/`.
Helpers in `Private/` are not exported.

### 6a. Loader variable naming in `*.psm1` (P-8 from the 2026-05-13 sweep)

The module loader's file-list arrays must not be named `$private` or `$public`
— `$private` is a PowerShell reserved scope-qualifier name; `$public` is not
reserved today but visually shadows the reserved namespace and confuses a
future maintainer.

```powershell
# Wrong — shadows the $Private: automatic scope qualifier
$private = Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1
$public  = Get-ChildItem -Path $PSScriptRoot\Public -Filter *.ps1

# Right
$privateFiles = Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1
$publicFiles  = Get-ChildItem -Path $PSScriptRoot\Public -Filter *.ps1
```

Reference fix: ClusterValidator commit `838e400` (2026-05-13). The suite
security sweep treats this as pattern P-8 — see
`cross-project-artifacts/handoff-2026-05-13-cwe-sweep.md`.

---

## 7. Decision Records (DRs)

Non-trivial design choices are written down before code is written. A decision
record lives in a project's `Docs/` folder, organized per the project's own
phase scheme.

The canonical DR template, status conventions (`OPEN`, `DECIDED (date)`,
`DECIDED · drift`, `OPEN · note`, `SUPERSEDED`), and the Drift-Notice and
Implementation-Note mechanics live in the **`dr-author`** skill. When working
on a DR-eligible decision, invoke that skill — don't reproduce the template
here.

A `Docs/DECISION_REGISTER.md` indexes all DRs with a dependency graph and a
status table. Each project maintains its own register.

---

## 8. Phase-Gated Development

Work is organized into phases. Each phase has explicit entry and exit criteria.
Code for a phase is only written when all blocking decisions for that phase
are resolved (DECIDED or OPEN-with-note).

**The phase model — count, numbering, naming, scope of each — is
project-defined.** This rule prescribes the *mechanic* (gating decisions
before code), not the schedule. ModuleWorkshop has Phase 1 active (pre-1.0)
and Phase 2 defined (opens at v1.0.0 tag); DBCCProject opens at Phase 0;
PesterForge currently runs Phases 1–3 plus a DR-26 coverage audit outside
the numbered ladder; PhotoOrganizer ships 2.0/2.1/3.0/3.1/3.2 sub-phases.
Don't paste a fixed 0–4 model into a new project's docs; let the project
define what a phase means.

Phases compose: a downstream phase cannot ship if an upstream phase is
incomplete. A phase that shipped despite OPEN gating decisions needs a
reconciliation pass — every DR either flips to DECIDED with the option the
code picked, or stays OPEN with an Implementation Note. The `phase-gate`
skill walks the reconciliation.

---

## 9. Four-Tier Confidence Model (when generating, inferring, or annotating)

When a tool emits an assertion, claim, or test, classify it into one of four
tiers. This is the central trust mechanism in PesterForge and applies any
time output mixes "definitely true" with "probably true" content.

| Tier | Label        | Source                                          | Output                     |
|------|--------------|-------------------------------------------------|----------------------------|
| 1    | Certain      | Literal value from AST / structured data        | Real assertion / claim     |
| 2    | Inferred     | Pattern-implied (AI, heuristic) — needs review  | Marked AI-INFERRED + reason|
| 3    | Behavioral   | Requires runtime / environment knowledge        | Stub with descriptive comment |
| 4    | Human-only   | Domain judgment, business rule                  | Stub with warning          |

Output never fakes confidence. A wrong Tier-1 assertion is worse than a Tier-3
stub. When a value cannot be classified into Tier 1, default to Tier 3 unless
a Tier-2 mechanism (AI enrichment, convention profile) covers it.

---

## 10. Anti-Patterns to Refuse

These patterns trigger pushback, not silent compliance:

- **Vibe content / fake examples.** `.EXAMPLE` blocks must be real, runnable,
  and demonstrate actual value. Placeholder examples like `Get-Thing -X 'foo'`
  with no context are worse than no example. Missing publisher help → labeled
  "Note for Users" admonition, not an AI invention.
- **Scope expansion to siblings.** Stay in the active project. Don't bundle
  "the same thing" into another of Keith's projects without explicit go-ahead.
- **Multi-project rewrites in one pass.** Even if the same fix applies to
  GitEasy and PesterForge, do them as separate, scoped changes.
- **Suppressing the never-throw rule.** Adding `throw` because "the caller can
  handle it" is wrong. Wrap and return a structured `HandledError`.
- **Mocking the database in integration tests.** Integration tests hit the
  real thing. Mocks belong in unit tests, not integration tests.
- **Bypassing safety checks.** Don't `--no-verify`, `--force-with-lease` to
  main, or skip state-checker output to "just get it done."
- **Making a flaky test pass.** Never skip it, add a sleep, or re-run it until
  it goes green. Find the root cause. If the cause cannot be found, delete the
  test and say why in the commit message. (Claude Code team practice, adopted
  2026-11-17; the `verify` skill carries the operating form.)
- **Comments that explain what code does** when the names already do.
  Comments are for *why* — hidden constraints, surprising behavior, the
  reason a workaround exists.
- **Trailing summaries on every response.** Keith reads diffs. State results
  and decisions; don't recap.

---

## 11. The GitEasy-First Rule

For any git operation in or across Keith's projects, prefer the **GitEasy**
module over raw `git` commands. The GitEasy public surface stays plain-English
(no jargon regression). Examples (from the 19-command 1.4.0 surface):
`Save-Work` (commit + push, with optional `-BumpVersion`), `Show-History`
(`-Graph` available), `Find-CodeChange` (the `git status` replacement),
`Search-History`, `New-Release`, `Show-Diagnostic`. If GitEasy lacks a needed
verb, raise it as a feature request rather than dropping to raw git in
business code.

---

## 12. Tools and References

Per-project tools live in `Tools/`:

- `Test-<Prefix>ProjectState.ps1` — state checker; first thing to run before
  modifying code; supports `-CiMode` for binary exit codes
- `New-<Prefix>ProjectScaffold.ps1` — idempotent scaffold creator
- `Invoke-<Prefix>Pester.ps1` — test runner that executes test files
  individually (Pester v3/4 cross-file contamination workaround)

### 12a. Signing-tool ProjectRoot manifest check (P-4 from the 2026-05-13 sweep)

Suite signing tools take a `-ProjectRoot` parameter and recursively walk
`<root>\<module>` and `<root>\Tools` to sign every `.ps1`/`.psm1`/`.psd1`.
A bare `[ValidateScript({ Test-Path -PathType Container })]` accepts any
ancestor directory — passing `C:\Sysadmin\Scripts` would attach the cert to
every sibling repo's files. With a CA-issued cert, that is forensically
expensive to unwind.

Every project's signing tool must verify a project-specific manifest exists
before walking files:

```powershell
$expectedManifest = Join-Path $ProjectRoot 'ModuleName\ModuleName.psd1'
if (-not (Test-Path -Path $expectedManifest -PathType Leaf)) {
    throw "ProjectRoot does not contain ModuleName.psd1 - refusing to sign files outside the intended distribution: $ProjectRoot"
}
```

Reference fix: ClusterValidator commit `baa6f4a` finding F-13 (2026-05-13)
in `Tools/Set-ClvAuthenticodeSignature.ps1`. The suite security sweep
treats this as pattern P-4 — see
`cross-project-artifacts/handoff-2026-05-13-cwe-sweep.md` for the full
catalog of eight patterns.

Memory files at `~/.claude/projects/C--Users-keith/memory/` carry persistent
context (Keith's role, project state, working rules). They are loaded into
every conversation; this skill complements them by making the discipline
actionable when the work begins.

---

## 13. Working with Keith

- **Terse responses.** A clear sentence beats a clear paragraph. No padding,
  no preamble, no recap.
- **Honest dissent.** When a request would create drift or violate a rule,
  say so before doing it. Don't comply silently and clean up later.
- **Confirm before acting on hard-to-reverse changes.** Pushing to main,
  destructive git operations, or changes that affect multiple projects
  need a check-in first.
- **Plain English explanations for "why."** When a design choice is novel,
  explain the *why* in one or two sentences. Don't lecture; don't hedge.
- **Match the scope.** A bug fix doesn't need a refactor. A one-off operation
  doesn't need a helper function. Three similar lines is better than a
  premature abstraction.

---

## When this skill triggers

This skill should be applied whenever:

- A new function, script, or module is being created in `C:\Sysadmin\Scripts\`
- An existing function in one of Keith's projects is being modified
- A design decision is being made (DR-eligible)
- A phase transition is being considered (Phase N complete → Phase N+1)
- Code is being reviewed for discipline compliance
- The question "should I do X this way?" comes up in a Keith project
- An anti-pattern is about to be committed

If in doubt, apply it. The cost of applying the discipline to non-Keith work
is small (the rules are mostly good practice anyway). The cost of *not*
applying it to Keith work is drift, jargon regression, or a vibe artifact
that has to be backed out.
