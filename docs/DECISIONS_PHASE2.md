# GitEasy — Decision Records, Phase 2 (Implementation)

Layout, test stack, and in-engine safety rails. Bootstrapped retroactively
2026-05-28; each DR cites the artifact it is sourced from.

---

## DR-008
# Decision Record 008 — `Public/`, `Private/`, single `.psm1` loader at root

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
What is the on-disk layout of the module — single monolithic `.psm1`,
multi-file with separate Public/Private folders, or some other shape?

## Context
The shipped layout is `GitEasy.psd1` + `GitEasy.psm1` at the repo root,
with `Public/`, `Private/`, `Format/`, `Assets/`, `Tests/`, `Tools/`,
`Wiki/`, and `docs/` as siblings. The `.psm1` loader dot-sources every
`.ps1` under `Private/` first, then `Public/`, then exports only the
public names per the manifest. This matches the suite convention used by
SqlInstanceForge, SqlCertForge, SqlSpnManager, and PhotoOrganizer.

## Decision
**Suite-standard layout.** `Public/`, `Private/`, and the loader at the
repo root. The loader is the only file that reads `$PSScriptRoot` (suite
rule 2).

## Source
- repo layout
- GitEasy.psm1 (the loader)
- tools/Run-GitEasyPester.ps1

## Phase
2

---

## DR-009
# Decision Record 009 — Pester 3 test stack (PowerShell 5.1 compatibility)

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
Which Pester major version backs the GitEasy test suite — Pester 3, or
the modern Pester 5?

## Context
The audience uses Windows PowerShell 5.1 by default; Pester 3 ships
on Windows out of the box, Pester 5 is an explicit `Install-Module`.
`tools/Run-GitEasyPester.ps1` runs against both PS 5.1 and PS 7 every
release, and the test files are Pester 3 shape (`Mock` syntax, `It` /
`Describe` blocks without Pester 5's discovery/execution split).
CHANGELOG 1.5.3 ships at 569 Pester 3 tests, 0 failures.

## Decision
**Pester 3.** The compatibility cost of Pester 5 (requires `Install-Module`,
discovery-phase rules change, BeforeAll/BeforeEach semantics differ) is not
worth the upgrade given Pester 3 covers every assertion shape the suite
needs.

## Source
- tools/Run-GitEasyPester.ps1
- Tests/*.Tests.ps1
- CHANGELOG 1.5.3 (569 tests on Pester 3.4.0)

## Phase
2

---

## DR-010
# Decision Record 010 — Fail-fast on unsafe Git state

## Status
DECIDED (retroactive, ratified 2026-05-28). **AMENDED 2026-06-06** per
DR-017 (Keith ratified): fail-fast remains the law for `Save-Work`,
`Switch-Work`, and `New-WorkBranch`. `Resolve-Conflict` is the single
sanctioned exception — it is allowed to operate on a repo with unresolved
*merge* conflicts because resolving them is its sole purpose. Rebase /
cherry-pick / revert / bisect in-progress states remain fail-fast for all
commands.

## Question
What does `Save-Work` (and other state-changing commands) do when the
working tree is in a half-done state — middle of a merge, rebase,
cherry-pick, revert, bisect, or with unresolved conflicts?

## Context
PROJECT_MANIFEST.md states "Fail fast on unsafe Git state" as an Immutable
Rule. The `Save-Work` CBH names every half-done state explicitly: "refuses
to run inside an unfinished merge, rebase, cherry-pick, revert, or bisect;
refuses to save while there are unfinished conflicts; tells you in plain
English when something is missing." `Assert-GESafeSave` is the private
helper that enforces this.

## Decision
**Refuse, do not muddle through.** Every state-changing command checks
for half-done Git state first and returns a refusal result with plain
English. Better to do nothing safely than do something that risks the
user's work.

## Source
- PROJECT_MANIFEST.md "Immutable Rules"
- Public/Save-Work.ps1 CBH
- Private/Assert-GESafeSave.ps1
- Tests/Unit/Assert-GESafeSave.Tests.ps1

## Phase
2

---

## DR-011
# Decision Record 011 — No here-strings in generated files (`.ps1`, `.psm1`); `.psd1` is exempt

## Status
DECIDED (retroactive, ratified 2026-05-28). **AMENDED 2026-05-28** per
suite-policy #2 (Keith ratified): load-bearing template here-strings (HTML,
CSS, SQL templates, etc.) may stay if they carry an inline `HERE-STRING
AUDIT (DR-011 amended 2026-05-28)` comment explaining the carve-out. The
ban still applies to incidental / convenience here-strings; the audit-comment
exemption is for genuine template bodies only.

## Question
Are PowerShell here-strings (`@"…"@` or `@'…'@`) allowed in this codebase?

## Context
PROJECT_MANIFEST.md states "No here-strings for generated files" as an
Immutable Rule. The reason (visible in CHANGELOG 1.5.3): line-ending
fragility under Pester 3 — a here-string in a `.ps1` / `.psm1` can fail
to parse depending on CRLF vs LF normalization across editors and CI.
The v1.5.3 release explicitly exempted `.psd1` because inline `ReleaseNotes`
is the natural shape for that field and the manifest is never re-parsed
by Pester 3.

## Decision
**No here-strings in `.ps1` or `.psm1`. `.psd1` is exempt** (the
`ReleaseNotes` field is the canonical use). The
`Tests/GitEasy.Manifest.Tests.ps1` suite enforces the rule and codifies
the `.psd1` exemption.

## Source
- PROJECT_MANIFEST.md "Immutable Rules"
- CHANGELOG 1.5.3 — `.psd1` exemption
- Tests/GitEasy.Manifest.Tests.ps1

## Phase
2
