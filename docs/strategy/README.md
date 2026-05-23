# GitEasy - Repo-architecture strategy

Three PlantUML diagrams comparing repo-organization proposals for GitEasy's
public launch. The diagrams are **strategic visualizations**, not code
architecture - they show what's public, what's private, and what flows
between them under each proposal. Supporting material for the 2026-05-20
CEO-mode evaluation in conversation; not a customer-facing deliverable.

## Diagrams

| # | View | What it shows |
|---|---|---|
| 01 | [Proposal A - Two-Repo Split](01-proposal-a-two-repo-split.puml) | Public `GitEasy` + private `GitEasy-internal`. Pristine public history. Manual operator discipline. Repo-as-share-mechanism for future collaborators. |
| 02 | [Proposal C - GitHub-Native](02-proposal-c-github-native.puml) | Single public repo + Issues + Wiki + private Project board. The OSS-standard pattern (dbatools, Pester, PSReadLine, AzureRM). Public roadmap visible by design; demands maintenance discipline that Keith has not yet tested. |
| 03 | [Proposal D - Claude-Era Hybrid](03-proposal-d-claude-era-hybrid.puml) | A's structure plus a Claude-built sync layer that mirrors internal `Roadmap.md` into public `roadmap`-labeled Issues. File-in-folder planning ergonomics on the inside; OSS-standard visibility on the outside; zero ongoing manual sync. |

## How to render

- VS Code: `jebbs.plantuml` extension, `Alt+D` preview on any `.puml`.
- One-off: paste a `.puml` into <https://www.plantuml.com/plantuml>.
- CLI: `java -jar plantuml.jar docs/strategy/*.puml`.

## Vocabulary (non-engineer-readable on purpose)

| Symbol | Means |
|---|---|
| **Package "Public"** | Anything anyone on the internet can read |
| **Package "Private"** | Anything only Keith (or invited collaborators) can read |
| **Cloud** | A GitHub-hosted artifact (repo, Issues, Wiki, Project board) or PowerShell Gallery |
| **Folder** | Local-only filesystem (Keith's machine) |
| **Component** | A discrete artifact: a folder of code, a planning document, a single script |
| **Solid arrow** | An actor actively reads from or writes to the target |
| **Dashed arrow** | Conditional / future access (e.g., granted on engagement) |
| **"AI session backups"** | Claude session state, handoff documents, scratchpads, decision-record drafts |

## Recommended path-of-travel (from the CEO-mode evaluation)

Not a fourth diagram - a temporal sequence over the three above.

1. **Now (0-30 days):** stand up Proposal A's two-repo structure. Trim the
   public repo per the Tier-1-through-Tier-5 split agreed in conversation.
   Stand up the private `GitEasy-internal` repo and move internal planning
   into it. Public history stays pristine going forward.
2. **Bridge (0-30 days, parallel):** enable GitHub Issues on the public
   repo for community bug reports. No `roadmap` label yet. This costs
   nothing and accepts inbound signal without committing Keith to maintain
   a visible roadmap.
3. **Build the sync layer (any afternoon when interrupt-budget allows):**
   author `tools/Sync-RoadmapToIssues.ps1` per Proposal D. Dry-run mode
   first, then scheduled.
4. **30-45 day decision point:** if community Issues are flowing AND Keith
   is responding within a week, the discipline test has passed - promote
   to Proposal D's full sync (roadmap items become public). If the funnel
   is silent, stay on A; revisit at 90 days.

## Honest gaps in this strategy view

- **Time dimension is absent from the diagrams themselves.** Each .puml is
  a snapshot. The "start with A, graduate to D" path-of-travel is captured
  in the section above and in conversation, not in the diagrams.
- **Cost per proposal is not quantified.** Rough operator-hours/month
  (carry these as estimates, not measurements): A ~2-3 hrs;
  C ~4-8 hrs if maintained honestly; D ~1-2 hrs after the one-afternoon
  sync-layer build.
- **Inbound-funnel signal is not modeled.** The visualizations show
  structure, not whether the public-roadmap signal under C or D actually
  generates inbound. That's what the staged graduation path is designed
  to measure.
- **No security trust-boundary view here.** This is a strategy view, not
  a security view. The trust boundary of the public PowerShell module is
  in [`docs/UML/02-internal-call-graph.puml`](../UML/02-internal-call-graph.puml)
  and the SECURITY-FINDINGS documents.
- **Proposal B is not diagrammed.** "Gitignored `internal/` + external
  backup" was cut from contention in the CEO-mode evaluation (loses git
  history on Decision Records; "external backup" is the placeholder that
  becomes "I forgot"). Drawing it would be padding for completeness, not
  insight - same anti-fabrication principle the editorial-stance enforces
  on user-facing docs.
- **Suite-wide binding is shown only implicitly.** Whatever pattern wins
  for GitEasy is the precedent for PesterForge, WikiEngine, ModuleWorkshop.
  Diagrams don't show the other three products; the binding is named in
  conversation.

## Reconciled against

- Working tree on 2026-05-20.
- Manifest `ModuleVersion = 1.5.2` (post sibling-sweep credential-surface release).
- CEO-mode evaluation in conversation, 2026-05-20.

If any of those dates feel stale when you read this, trust conversation
or the manifest over the diagrams.
