---
name: blog-proposal
description: Use when Keith asks for a blog post draft, blog proposal, or "write a post about X." Generates a dev.to-compatible Markdown draft (frontmatter + body) targeting his https://dev.to/greenmtnsun audience. Drops the file into C:\Sysadmin\Scripts\Blog-Drafts\ for him to review, edit, and publish manually. Voice is pastoral-trained-communicator, technical-but-accessible, anti-vibe (no fabricated claims), professional. Surfaces newsworthy items only — features that are real, shipping, and hold up to a developer audience.
---

> See also: `editorial-stance` for the anti-vibe rule that applies to every word published. `module-suite` for what counts as a real product vs speculative.

# Blog proposal — drafting posts for dev.to/greenmtnsun

## Why this skill exists

Keith wants distinctive credibility on dev.to without the outbound-sales feel. A draft-then-review-then-publish flow lets him build a back catalog at his pace, in his voice, on his terms. The skill handles the typing; he handles the publishing decision.

His brand positioning (per memory):

- Pastoral-trained communicator with real stage time — not a YouTube-influencer voice.
- Technical depth that does not need to flex; results speak.
- Anti-vibe stance is a *feature* of the brand, not a quirk to hide.
- Professional, calm, occasionally dry. Not breathy hype.
- "Force to be reckoned with" by quality of work, not volume of noise.

## What counts as newsworthy

Lean toward proposing posts about:

- **Shipping releases of real products.** GitEasy 1.4.0 (19 commands, zero jargon) — safest example. PesterForge milestones once shipping. Concrete version numbers, concrete features.
- **ClusterValidator caveat:** despite being a personal SQL FCI validator, its phase names (LunHygiene, Identity, etc.) and validation depth derive from real-world enterprise SQL ops experience. Before drafting any ClusterValidator-related post, run a work/personal-separation check (`feedback_work_personal_separation.md`): nothing in the post should describe a specific work environment, host, customer, or implementation detail Keith encountered on the job. Confirm with Keith before drafting if uncertain.
- **Genuinely distinctive patterns.** The air-gap-sentinel hook. The editorial-stance / anti-vibe rule. The provenance-stamping idea. The DR-discipline applied at suite scale by one person.
- **Lessons from real fixes.** "I built 23 hook tests and 4 of them failed — here's what I learned about PowerShell approved verbs." Specific, narratable, useful.
- **Cross-cutting industry observations.** "Why honest gaps beat AI-padded docs." Opinion grounded in shipping work.

Skip / refuse:

- Posts about products that haven't shipped (ModuleWorkshop is speculative; don't write a hype post about it).
- Posts about the "fifth module" or any pre-decision concept.
- Generic listicles ("10 PowerShell tips") that don't carry his voice.
- Anything that violates the editorial-stance rule (fabricated benchmarks, invented user testimonials, made-up numbers).
- Hot takes on tools he hasn't used.

## Output format

Dev.to expects Markdown with YAML frontmatter:

```markdown
---
title: <Sentence-case title — concrete, specific, not clickbait>
published: false
description: <One sentence — what the post delivers, not what it teases>
tags: powershell, <2–3 more relevant tags from dev.to's taxonomy>
canonical_url: <optional — if Keith publishes elsewhere first>
cover_image: <optional — leave commented if not selected>
---

<Body in Markdown. Headings, code blocks, lists. No emojis unless Keith asks.>
```

`published: false` is the default and stays false until Keith manually edits it. The skill never sets `published: true`.

## Output location

```
C:\Sysadmin\Scripts\Blog-Drafts\YYYY-MM-DD-<slug>.md
```

Where `slug` is a kebab-case shortening of the title.

If a draft on the same topic already exists (file with matching slug), do not overwrite. Append a `-v2`, `-v3` suffix or ask Keith.

## Voice rules

*(Voice mechanics — AI-tell stripping, no honesty narration — are canonical in `humanized-writing` + CLAUDE.md §10; the rules below are the blog-specific layer on top, per the one-home rule, cross-linked 2026-08-15.)*

1. **Lead with the concrete.** Open with a specific result or finding, not a general observation. "I shipped GitEasy 1.4.0 last week with 19 commands and zero git-jargon in the user surface" beats "Let's talk about plain-English CLIs."
2. **Show the code or the receipt.** A claim about a feature comes with a runnable example or a screenshot-equivalent prose description. No vague "this makes things better."
3. **Honest scope.** "I built this for a one-person suite; YMMV at scale" is more credible than "this scales to enterprise" with no enterprise users.
4. **Cite priors.** When a pattern derives from dbatools / PSFramework / others, name them. The Master-Directive's framing rule applies: pattern recognition wins; pretending novelty loses.
5. **End with a question or invitation.** Dev.to comments thrive on prompts. Keith is a trained communicator; a real question gets real engagement.
6. **No emojis unless asked.** Per Claude Code conventions and Keith's working preferences.
7. **Length.** 600–1200 words for the body. Long enough to deliver substance; short enough to read on a coffee break. Headlines/H2s every 200–300 words for scannability.
8. **Audience routing.** The title + tags together must state *who the post is for*, specifically enough that a recommendation algorithm (and a skimming human) can route it to the right reader. "Pester tests for SQL Server DBAs on PowerShell 5.1" routes; "Testing best practices" doesn't. This is clarity, not tag-stuffing — the intended-reader check happens before the draft is saved, and a draft whose title could head anyone's post gets retitled.

## Tag conventions for dev.to

Default tag pool (combine 3–4 per post):

- `powershell` (always for PowerShell content)
- `devops` (for tooling / CI / hooks posts)
- `sql` or `sqlserver` (for SQL-flavored content)
- `productivity` (for workflow patterns)
- `opensource` (when discussing GitEasy or other public modules)
- `ai` (sparingly — only for posts that genuinely engage with AI in dev work, not as keyword-stuffing)
- `dba` (for DBA-audience-specific content; rare since the rule is neutral framing)

## How this skill is invoked

Keith says one of:

- "Blog about <topic>"
- "Draft a post on <topic>"
- "Write a blog proposal for <topic>"
- "Make a dev.to post about <topic>"
- "Blog the <release-or-feature>"

The skill:

1. Confirms the topic is *newsworthy* per the criteria above. If not, push back: "That's speculative — skip the post until it ships."
2. Asks one or two clarifying questions if the angle isn't obvious (e.g. "Lessons-learned style or release-announcement style?").
3. Drafts the file. Saves to `C:\Sysadmin\Scripts\Blog-Drafts\YYYY-MM-DD-slug.md`.
4. Reports the path back to Keith. Does not auto-publish, does not push to remote, does not modify any blog repo.

## What this skill does NOT do

- Does not auto-publish to dev.to. Editorial-stance is the moat; humans approve content.
- Does not generate posts about speculative or unshipped work.
- Does not invent metrics, benchmarks, user counts, or testimonials.
- Does not stuff tags for SEO. The point is finding readers who care, not gaming the algorithm.
- Does not write in the first person if Keith hasn't given the angle. Default to first-person ("I shipped...") since that's his voice; ask if a different POV fits.
- Does not propose more than one draft per invocation unless Keith asks for variations.

## Pairing with future scheduled-newsworthy-digest

The on-demand skill above is the first half. A scheduled remote agent (separate, future build) could fire weekly, scan recent commits / releases / DRs across all suite projects, and *propose candidates* — names of newsworthy items, not full drafts. Keith picks one or two to draft via this skill. That's the natural extension; not built yet.
