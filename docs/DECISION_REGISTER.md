# GitEasy — Decision Register

Index of every Decision Record. Status verbatim from `DECISIONS_PHASE<N>.md`.
This register was bootstrapped retroactively 2026-05-28; each DR cites the
real artifact the decision is sourced from. Nothing is invented.

## Status table

| DR | Title | Status | Phase | Source |
|----|-------|--------|-------|--------|
| [DR-001](DECISIONS_PHASE1.md#dr-001) | Plain-English public surface — no Git jargon in command names or returned data | DECIDED (retroactive, original ~v1.0.0) | 1 | README.md "From Keith"; docs/HOW-TO-USE-GITEASY.md |
| [DR-002](DECISIONS_PHASE1.md#dr-002) | Private helpers use the `GE` prefix; public commands do not | DECIDED (retroactive) | 1 | PROJECT_MANIFEST.md "Immutable Rules" |
| [DR-003](DECISIONS_PHASE1.md#dr-003) | License is MPL-2.0; project survives independent of the author | DECIDED (retroactive) | 1 | LICENSE; README.md "From Keith" |
| [DR-004](DECISIONS_PHASE1.md#dr-004) | PowerShell-only — no cross-language dependencies, no compiled binaries shipped with the module | DECIDED (retroactive) | 1 | PROJECT_MANIFEST.md "Immutable Rules" |
| [DR-005](DECISIONS_PHASE1.md#dr-005) | Structured-result return on every public command path, including `-WhatIf` and refusal paths | DECIDED (retroactive) | 1 | CHANGELOG 1.5.2 fix-list (Set-Vault gap) |
| [DR-006](DECISIONS_PHASE1.md#dr-006) | One log file per invocation; logs land under `%LOCALAPPDATA%\GitEasy\Logs\` by default | DECIDED (retroactive) | 1 | docs/FOR-GIT-EXPERTS.md; CHANGELOG references |
| [DR-007](DECISIONS_PHASE1.md#dr-007) | Vault-based credential storage; never embed credentials in remote URLs | DECIDED (retroactive) | 1 | Public/Set-Vault.ps1, Set-Token.ps1, Get-VaultStatus.ps1 |
| [DR-008](DECISIONS_PHASE2.md#dr-008) | `Public/`, `Private/`, single `.psm1` loader at root; suite-standard layout | DECIDED (retroactive) | 2 | repo layout; tools/Run-GitEasyPester.ps1 |
| [DR-009](DECISIONS_PHASE2.md#dr-009) | Pester 3 test stack — picked for Windows PowerShell 5.1 compatibility | DECIDED (retroactive) | 2 | tools/Run-GitEasyPester.ps1; Tests/*.Tests.ps1 |
| [DR-010](DECISIONS_PHASE2.md#dr-010) | Fail-fast on unsafe Git state — refuse to operate inside an unfinished merge/rebase/cherry-pick/revert/bisect or with unresolved conflicts | DECIDED (retroactive) | 2 | PROJECT_MANIFEST.md "Immutable Rules"; Public/Save-Work.ps1 CBH |
| [DR-011](DECISIONS_PHASE2.md#dr-011) | No here-strings in generated files (`.ps1` / `.psm1`); the `.psd1` is exempt because inline `ReleaseNotes` is the natural shape | DECIDED (retroactive) | 2 | PROJECT_MANIFEST.md "Immutable Rules"; CHANGELOG 1.5.3 (.psd1 exemption) |
| [DR-012](DECISIONS_PHASE3.md#dr-012) | Credential-safe URL handling: every URL on a log/output/error path passes through `Format-GESafeUrl`; every argument list passed to `git` is sanitized before being echoed | DECIDED (retroactive — closed at v1.5.2) | 3 | CHANGELOG 1.5.2 F-04/F-05/F-06; docs/SECURITY-FINDINGS-2026-05-20.md |
| [DR-013](DECISIONS_PHASE3.md#dr-013) | Test-GERemoteUrlSafe is the single accept/reject gate for any URL the module will write back to disk or pass to git | DECIDED (retroactive) | 3 | CHANGELOG 1.5.2; Private/Test-GERemoteUrlSafe.ps1 |
| [DR-014](DECISIONS_PHASE3.md#dr-014) | PSGallery metadata is audience-first: `Description` under 400 chars and named for sysadmins/change-managers/compliance; `LicenseUri` points at the in-repo LICENSE file; inline plaintext `ReleaseNotes` | DECIDED (retroactive — shipped at v1.5.3) | 3 | CHANGELOG 1.5.3; docs/PSGALLERY-METADATA-PLAYBOOK.md |
| [DR-015](DECISIONS_PHASE3.md#dr-015) | No CLA today; external pull requests not accepted until the contribution path is resolved. The contribution door is "closed for now," not bolted | DECIDED (retroactive) | 3 | README.md "From Keith"; README.md 2026-05-22 note |
| [DR-016](DECISIONS_PHASE4.md#dr-016) | UML rebuild from 3 of 12 to 12 of 12, phased across 3 follow-on sessions (Foundational / Behavioral / Cross-product) | DECIDED (2026-05-28); implementation Phase 4 follow-on | 4 | full suite-standard UML coverage |

## Phase model

- **Phase 1 — Design**: foundational design choices that shape the public
  surface and the engine's contracts. (CLOSED.)
- **Phase 2 — Implementation**: layout, test stack, in-engine safety rails.
  (CLOSED.)
- **Phase 3 — Hardening + first public release**: security review, PSGallery
  publishing prep, license / governance choices. (CLOSED at v1.5.3 / v1.5.4.)
- **Phase 4 — Maintenance**: bug-fix releases and named additions. (ACTIVE.)
