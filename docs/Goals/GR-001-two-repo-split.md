---
id: GR-001
title: Execute the two-repo public/private split
status: OPEN
phase: ongoing
opened: 2026-05-23
closed:
linked-drs: []
linked-plan: docs/strategy/README.md
---

# GR-001 — Execute the two-repo public/private split

## Why

The 2026-05-20 CEO-mode evaluation chose Proposal A (public `GitEasy` + private `GitEasy-internal`). The strategy is committed at `docs/strategy/`. Tonight's classification audit confirmed the split lines for 80% of the tree; six items remain DISCUSS-tier and need Keith's call. Executing the split unblocks PSGallery URI 404s (the manifest URIs resolve once the public repo is genuinely public) and creates the clean separation between publish-surface and internal planning that the suite needs as a precedent for PesterForge, WikiEngine, ModuleWorkshop.

## Acceptance criteria — autonomous (`/goal` drives these)

- [ ] `docs/Decisions/DR-001-tier-classifications.md` exists with explicit decisions on all six DISCUSS items from the 2026-05-23 classifier report (PROJECT_MANIFEST.md, Update-GitEasy*Wiki.ps1 x2, wrangler.jsonc, tools/Publish-GitEasy.ps1, docs/PSGALLERY-METADATA-PLAYBOOK.md, docs/wiki/ empty dir)
- [ ] `greenmtnsun/GitEasy-internal` remote exists and is reachable (`gh repo view greenmtnsun/GitEasy-internal` returns 200)
- [ ] All PRIVATE-tier files from DR-001 are present in `GitEasy-internal` and absent from `GitEasy` (verified by `gh api` file existence checks on both repos)
- [ ] `GitEasy` repo builds clean: `Test-ModuleManifest` passes, `Import-Module` succeeds, `Get-Module GitEasy` shows 21 functions + 3 aliases
- [ ] `GitEasy-internal` README explains what lives there and points at `git-easy.com` for the public-facing project

## Acceptance criteria — human-gated (STOP loop, hand off to Keith)

- [ ] Keith decides the six DISCUSS classifications (will be surfaced via UI)
- [ ] Keith creates `greenmtnsun/GitEasy-internal` on GitHub (private; we can prep but creating repos in his account requires his auth)
- [ ] Keith authorizes the file moves (we will produce a dry-run plan first)

## Non-goals

- Flipping `greenmtnsun/GitEasy` from private → public. That depends on GR-002 (PR-refs purged) closing first. Tracked separately.
- Updating `ProjectUri` / `LicenseUri` / `IconUri` in the manifest. Those become live once the repo is public; manifest edit is part of the publish goal, not this split.
- Setting up the Claude-era sync layer (Proposal D bridge). That's the post-30-day graduation step, not in scope here.

## Linked work

- Plans: `docs/strategy/README.md`, `docs/strategy/01-proposal-a-two-repo-split.puml`
- Decisions: [[DR-001-tier-classifications]] (to be written)
- Phase: ongoing

## Status log

- 2026-05-23 opened OPEN
