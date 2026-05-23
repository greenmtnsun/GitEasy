---
id: DR-001
title: Tier classifications for the two-repo public/private split
status: DECIDED
decided: 2026-05-23
phase: ongoing
linked-goals: [GR-001]
---

# DR-001 — Tier classifications for the two-repo public/private split

## Decision

For the upcoming two-repo split per Proposal A:

- **PUBLIC repo (`greenmtnsun/GitEasy`)** holds the module surface and a narrow set of brand / hosting artifacts that the user community actually benefits from seeing.
- **PRIVATE repo (`greenmtnsun/GitEasy-internal`)** holds everything else by default — planning, dev tooling, internal docs, AI session backups.

## Policy

> Default: PRIVATE.
> Exception: items that a non-developer technical user (sysadmin, DBA, change manager — GitEasy's audience) would actually want to see.

This is a deliberate inversion of the OSS-default "everything public unless reason to hide." GitEasy's audience is not full-time developers; they don't browse repos for fun. They install from PSGallery, read the README and the marketing site, and move on. Items that don't help that audience stay out of the public surface.

## Classifications (canonical list)

Resolved by classifier agent on 2026-05-23 + this DR. Six DISCUSS-tier items the agent flagged are decided below; the agent's clean PUBLIC / PRIVATE calls on the other 80% of the tree stand as-is.

### PUBLIC by clean-call (from classifier, no DR needed)

`.gitignore`, `CHANGELOG.md`, `CONTRIBUTING.md`, `GitEasy.psd1`, `GitEasy.psm1`, `LICENSE`, `README.md`, `.github/` tree (`ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE.md`, `workflows/pester.yml`), `Assets/` (`ICON-SPEC.md`, `icon.png`), `Examples/`, `Format/`, `Private/` (PowerShell-scope private, ships in module), `Public/`, `Tests/`, `docs/COMMAND_EXAMPLES.md`, `docs/FOR-GIT-EXPERTS.md`, `docs/GITEASY-VS-RAW-GIT.md`, `docs/HOW-TO-USE-GITEASY.md`, `docs/QUICKSTART.md`, `docs/USING-IN-CI-AND-AGENTS.md`, `docs/SECURITY-FINDINGS-2026-05-17.md`, `docs/SECURITY-FINDINGS-2026-05-20.md`, `docs/UML/`, `docs/images/`, `site/`, `tools/Audit-GEUsage.ps1`, `tools/Audit-PublicJargon.ps1`, `tools/Build-DocsPdf.ps1`, `tools/Build-PrivateUnitTests.ps1`, `tools/Build-PublicUnitTests.ps1`, `tools/Build-SiteCommands.ps1`, `tools/Install-GitEasy.ps1`, `tools/Install-LocalPreview.ps1`, `tools/Run-GitEasyPester.ps1`, `tools/Run-GitEasyTest.ps1`.

### PRIVATE by clean-call (from classifier, no DR needed)

`.claude/` tree, `Wiki/` tree (local clone, gitignored), `coverage.txt` (gitignored).

### DISCUSS-tier — resolved by this DR

| Item | Default | This DR | Why |
|---|---|---|---|
| `PROJECT_MANIFEST.md` | PRIVATE | **PUBLIC** (exception) | 7 lines of project philosophy. Sysadmin evaluators read it to decide if GitEasy's posture matches theirs. Brand-positive; no sensitive content. |
| `Update-GitEasyCommandWiki.ps1` | PRIVATE | **PRIVATE** | Dev tooling. Generates GitHub Wiki content from module CBH. End users never invoke it. |
| `Update-GitEasyPrivateWiki.ps1` | PRIVATE | **PRIVATE** | Same shape; even more internal (writes to a separate local clone). |
| `wrangler.jsonc` | PRIVATE | **PUBLIC** (exception) | Hosting requirement, not a user-community want. Cloudflare Pages auto-deploys `git-easy.com` from this repo; the config must live where the build runs. No secrets (just project name + asset path). The alternative (move site to a separate repo) is out of scope. |
| `tools/Publish-GitEasy.ps1` | PRIVATE | **PRIVATE** | Supply-chain-transparency value exists but matters to a tiny subset (security-paranoid evaluators). Under the "almost everything PRIVATE" stance, that subset is too narrow to justify exposure. |
| `docs/PSGALLERY-METADATA-PLAYBOOK.md` | PRIVATE | **PRIVATE** | Maintainer / forker reference, not user-facing. |
| `docs/wiki/` (empty dir) | — | **DELETE** | Empty placeholder. Removed during the split. |

### Tracked PRIVATE-tier additions (already in `docs/` but planning-tier)

`docs/GOALS.md`, `docs/Goals/` (entire dir including this DR), `docs/Decisions/` (entire dir including this DR), `docs/strategy/` (the Proposal A/C/D evaluation that motivated the whole split).

## Net counts

- PUBLIC: ~60 files / dirs (module surface + brand + hosting)
- PRIVATE: ~10 files / dirs (tooling, planning, AI session data)
- DELETED: 1 (empty placeholder)

## Why this stance (not OSS-default)

Three reasons:

1. **Audience signal.** GitEasy's users don't browse repos. A smaller public surface is honest about who reads it; padding the public repo with tooling they'll never run is brand noise.
2. **Operational discipline.** Keith is a solo operator. Less public surface = less to maintain in a publicly-readable state. The graduation path (Proposal D's roadmap-sync layer) opens specific channels for community signal without committing to a full public roadmap.
3. **No regret.** Items can move PRIVATE → PUBLIC at any time with a single commit. PUBLIC → PRIVATE is harder once published. Default tight; relax only when a real user-community want emerges.

## Non-decisions

- This DR does not decide when to flip the public repo from private to public. That depends on GR-002 (PR-refs purged) closing.
- This DR does not decide the schedule for graduation to Proposal D (sync layer). Revisit at the 30-day mark per `docs/strategy/README.md`.
- This DR does not classify any future addition. New top-level files require either a tier call against this policy or an amendment to this DR.

## Status log

- 2026-05-23 OPEN → DECIDED in single session. Authored by Claude with Keith's policy direction; Keith's two exceptions (PROJECT_MANIFEST.md, wrangler.jsonc) approved by his "tell me what the community would want and we can make exceptions" framing followed by reasoned recommendation.
