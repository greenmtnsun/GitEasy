---
name: module-suite
description: Use for cross-product strategy across Keith's PowerShell Module Suite (WikiEngine, PesterForge, ModuleWorkshop, GitEasy) — schema-as-contract decisions, Atlassian Marketplace listing shape, sequencing decisions across the four products, editorial-stance enforcement (anti-vibe), which product to ship first. Encodes architectural rules, decision heuristics, repo locations. Distinct from software-creation, which covers per-file craft within any single project.
---

> See also: `software-creation` for per-file craft discipline.

# Module Suite — operating manual

Keith is building a **PowerShell Module Suite**: four single-purpose products that span the module lifecycle, sharing one harvest engine and one JSON schema. Treat the suite — not any one repo — as the unit of strategy.

> **Scope note (2026-05-07):** Suite membership is provisional. Keith has ~11 PowerShell modules in development under `C:\Sysadmin\Scripts\` and may productize additional SQL-track modules (DBCCProject / SqlBackupValidation, ClusterValidator, dbaReplication, etc.). The four below are the working go-to-market list at this point in time; expect it to evolve. When in doubt about membership, ask Keith — don't categorize unilaterally.

## The four products (working go-to-market list)

| Product | Lifecycle stage | Maturity (point-in-time) | GitHub | Local |
|---|---|---|---|---|
| **GitEasy** | Author | v1.4.0 (shipping) — see `project_giteasy.md` | `greenmtnsun/GitEasy` | `C:\Sysadmin\Scripts\GitEasy` |
| **ModuleWorkshop** | Package | v0.9.99 pre-1.0; full Tier 1–4 house-style alignment landed — see `project_moduleworkshop.md` | `greenmtnsun/ModuleWorkshop` | `C:\Sysadmin\Scripts\ModuleWorkshop` |
| **PesterForge** | Test | 0.1.0 with Phases 1/2/3 + DR-026 (published 2026-05-07) — see `project_pesterforge.md` | `greenmtnsun/PesterForge` | `C:\Sysadmin\Scripts\PesterForge` |
| **WikiEngine** | Document | Engine working, public site on MkDocs Material — see `project_wikiengine.md` | `greenmtnsun/PS-Wiki-Central` | `C:\Sysadmin\Scripts\WikiEngine` |

For current state of any product, the `project_<name>.md` memory entry is authoritative — this table drifts. ModuleWorkshop has the broadest buyer base and may justify shipping to Atlassian Marketplace **first** — ahead of even the WikiEngine Confluence plugin. Don't assume WikiEngine is the flagship.

## The integration spine — schema as contract

The four products are **not** merging codebases. The integration point is a shared JSON schema:

```
{ CommandName, Author, Synopsis, Description, Parameters[], Examples[] }
```

(WikiEngine is the baseline. PesterForge will need additional fields like return type and parameter validators.)

**Rule:** When proposing cross-product changes, modify the schema, not the products. The schema is the only thing both products read. A top-level `SCHEMA.md` is on the roadmap as the source of truth.

The harvest engine's old home (`C:\Sysadmin\Scripts\dbaDocs-Advanced\dbaDocsEngine\dbaDocsEngine.psm1`) is EMPTY — the directory exists with zero items (verified 2026-08-15); the planned consolidation under WikiEngine evidently happened or the engine moved. Locate the current engine inside the WikiEngine repo before citing paths. Historical function names: `Invoke-DbaWikiForge` (renderer), `Export-DbaDocsData` (harvester).

## Editorial stance — anti-vibe (load-bearing)

The full rule, the three machine-verified suppression behaviors, and the Confluence-storage-format mapping live in the **`editorial-stance`** skill. Summary: honest gaps over fabricated content; pinned by ~30 Pester tests in `WikiEngine\Confluence\ConfluenceStorage.Tests.ps1`. Apply to every renderer (Markdown, Confluence, future MCP / second-language). Historical exception: `SqlSpnManager`'s 6 pages carry `"Author": "Rogue AI Synthesis"` and are a flagged decision.

## Side-hustle context

Keith earns ~$160k/year as a Sr DBA contractor at DOE/BPA. The Module Suite is a personal side hustle built in spare time. Hours per week are real but variable.

**What this means in practice:**
- Suite revenue replacing primary income is a long-arc aspiration, not a near-term plan.
- Time is a real constraint; some products may sit in maintenance-mode while others get attention.
- **Innovation and exploration are first-class.** Welcome speculative, generative, or playful ideas — sketch first, filter later if at all. Surface tradeoffs when Keith asks; lean against preemptively rejecting ideas on ROI or hours-budget grounds. There are real cases where that math matters; let Keith name them.

> **TODO (Keith):** Nuanced triage rules — when ROI / hours-math should fire, when it shouldn't, what counts as "mature enough to weigh" vs "still exploring" — to be drafted later. Until then, this section intentionally omits the gates that would prematurely kill exploration.

## Architectural rules

1. **Schema-first.** Cross-product needs go through the JSON schema, not coupled code.
2. **Single-purpose products.** Don't grow features in one product that belong in another (e.g., test generation belongs in PesterForge, not WikiEngine).
3. **Language as a plug-in.** The renderer should be language-aware (PowerShell today; VBA / PL-SQL are stronger moat fits than Python per the brittle-stack thesis). Add a `Language` field to schema before second-language work.
4. **Editorial stance carries to every renderer.** NfU, Synopsis suppression, empty-Examples filtering — same behavior across Markdown, Confluence storage format, future MCP output.
5. **No codebase merging.** The suite is four products, not one mega-repo.

## Decision heuristics — when in doubt

When Keith asks "should I…?", answer the question. When he's explicitly weighing options, surface relevant tradeoffs:

1. **Editorial stance check.** If a suggestion would have the engine fabricate content, reject and propose the honest alternative. This is the only reflexive filter — it's load-bearing for the public wiki's integrity.
2. **Schema impact.** If the change touches the JSON schema, name which other products consume that field before recommending.
3. **Sequencing assumptions.** Don't default to "WikiEngine is the priority" — ModuleWorkshop may ship first. Don't assume any product's priority without checking.
4. **ROI / hours framing.** A tool Keith can request explicitly ("weigh this against my hours budget"). Not the default lens for evaluating fresh ideas.

## Repo locations (quick reference)

- GitEasy: `C:\Sysadmin\Scripts\GitEasy` (GitHub `greenmtnsun/GitEasy`)
- ModuleWorkshop: `C:\Sysadmin\Scripts\ModuleWorkshop` (GitHub `greenmtnsun/ModuleWorkshop`)
- PesterForge: `C:\Sysadmin\Scripts\PesterForge` (GitHub `greenmtnsun/PesterForge`)
- WikiEngine: `C:\Sysadmin\Scripts\WikiEngine` (GitHub `greenmtnsun/PS-Wiki-Central`)
- Harvest engine (pending consolidation): `C:\Sysadmin\Scripts\dbaDocs-Advanced\dbaDocsEngine\`
- Other suite-adjacent modules (membership provisional): ClusterValidator, dbaReplication, DBCCProject (module name `SqlBackupValidation`), SqlSpnManager, SQLMonitorBackups, SqlTechnicalSanity — all under `C:\Sysadmin\Scripts\`. PhotoOrganizer is personal-only.
- `PSModuleHarvestAudit` — Keith mentioned this name; public 404 under `greenmtnsun`. May be private, planned, or a typo. **Confirm before recommending it as an integration point.**

## Open suite-level decisions (track these)

These gate concrete work. Surface them when relevant rather than picking unilaterally:

- **Project naming.** "PowerShell Intelligence Hub" undersells a multi-product suite that also generates tests and packages modules. "PowerShell Module Suite" is the working name.
- **Marketplace listing shape.** One suite-level listing vs. per-product listings cross-promoting.
- **Year 1 sequencing.** Ship ModuleWorkshop first (more production-ready, broader buyer) vs. WikiEngine Confluence plugin first.
- **Second language commitment.** VBA / PL-SQL (moat) vs. Python (reach) vs. wait-until-customer-asks.
- **Per-product triage.** Which of the four are full-development, which go to maintenance-mode given the hours budget.
