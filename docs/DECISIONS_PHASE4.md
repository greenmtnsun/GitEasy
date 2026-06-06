# GitEasy — Decision Records, Phase 4 (Maintenance)

Active phase. New DRs are authored here as Maintenance-phase choices arise.

---

## DR-016
# Decision Record 016 — UML rebuild from 3 of 12 to 12 of 12, phased across multiple sessions

## Status
DECIDED (2026-05-28; implementation phased Phase 4 across follow-on
sessions).

## Question
The conformance audit flagged GitEasy's UML coverage at 3 of the
suite-standard 12 diagrams. Keith said yes to a full rebuild
(checklist #13). What's the phasing, and what's in each session?

## Context
The suite-standard 12-diagram set (per ClusterValidator DR-014, the
reference corpus) covers: 01 use case, 02 deployment, 03 package,
04 trust boundary, 05–10 sequence flows, 11 class data contracts,
12 dependency graph. Authoring 12 diagrams in one session sacrifices
diagram correctness for throughput; phasing gives each diagram a
proper read-the-actual-code-before-drawing pass.

Existing GitEasy UML lives at `docs/UML/` (3 diagrams already
present). The rebuild ADDS to them, not replaces, unless an
existing diagram needs corrections after the read-the-code pass.

## Decision
**Phased build, three clusters, three follow-on sessions:**

1. **Foundational (one session)** — 01-use-case, 02-deployment,
   03-package, `docs/UML/README.md` (set the README + convention
   reminder for the corpus). If the existing 3 diagrams cover any of
   these slots, ratify them or replace; the existing PlantUML
   sources at `docs/UML/` are the audit point.

2. **Behavioral (one session)** — 04-trust-boundary,
   05/06/07/08 sequence flows (the canonical Save-Work safe-Git
   refusal path; the credential vault read path; the publish-readiness
   surface; the test-runner-cross-edition flow). Pulls from
   PROJECT_MANIFEST.md "Immutable Rules" and the F-01..F-06 security
   findings docs.

3. **Cross-product (one session)** — 09/10 sequence flows
   covering the suite-cross-product surface (GitEasy invoked from
   PesterForge, ModuleWorkshop, etc.), 11-class-data-contracts (the
   structured-result return shape per DR-005), 12-dependency-graph
   (the .psm1 loader graph; the relationship to git.exe and
   cmdkey.exe).

Source-only PlantUML; no rendered images committed (suite convention).
Each session ends with `Tools/Run-GitEasyPester.ps1` green and the
diagram(s) added at `docs/UML/` referencing the actual code they
document.

## Source
- Existing `docs/UML/` (3 diagrams)
- Suite reference: ClusterValidator docs/UML/ (12-diagram reference),
  SqlInstanceForge SqlInstanceForge/Docs/UML/, SqlCertForge Docs/UML/.
- cross-suite skill: virtual-uml-architect

## Phase
4 (decision); follow-on Phase 4 sessions (implementation across the
three clusters above)
