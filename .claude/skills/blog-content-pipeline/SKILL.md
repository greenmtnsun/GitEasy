---
name: blog-content-pipeline
description: Self-healing pipeline for a markdown blog post (or a batch of them) — generate/edit in the established voice, run the deterministic Test-BlogContent.ps1 checker (link crawl, image render, code-block execution), judge fabricated claims and voice authenticity, rewrite anything below threshold, and re-check until it passes or hits the retry cap. Use when Keith asks to "audit," "self-heal," or "pipeline" blog content for keith-ramsey.com (KeithsWebsite), PesterForge's Docs/Blog series, or any other project with a markdown content directory. Only report posts that pass every check as ready; held posts are listed with the specific unresolved reason, never silently dropped.
---

> See also: `editorial-stance` and `feedback_wikiengine_anti_vibe` for the never-fabricate rule this pipeline enforces mechanically. `blog-proposal` for drafting a brand-new post (this skill audits/heals it once drafted). `feedback_deploy_requires_explicit_go` — this pipeline never publishes; it only produces a pass/hold report.

# Blog content pipeline

## Why this exists

Keith's blog work (KeithsWebsite / keith-ramsey.com, PesterForge's Pester-for-Beginners series, and future project blogs) has repeatedly shipped with broken links, missing images, and fabricated claims that only surfaced after Keith caught them live. This pipeline moves that catch earlier and makes it mechanical instead of relying on a human proofread every time.

It is a two-layer system:

1. **Deterministic layer** — `tools/Test-BlogContent.ps1` (per-repo copy; the reference implementation lives at `C:\Sysadmin\KeithsWebsite\tools\Test-BlogContent.ps1`). Crawls every link and image reference and reports real HTTP/file-system ground truth; extracts every fenced code block and actually executes it (PowerShell, Pester `Describe`/`It` blocks via `Invoke-Pester`, Python, Bash) in an isolated temp directory, never against Keith's real filesystem state. Never invents a verdict — everything is a real HTTP status, a real decoded image, or a real execution result.
2. **Judgment layer** — you (Claude), reading the checker's JSON output plus the full post. This is where fabrication-checking, voice-scoring, and "was that error intended" calls happen — things a regex genuinely cannot decide.

## Step-by-step

**0. Confirm the target before running anything.** State the repo, the `-ContentPath`, and the `-RepoRoot` you're about to point the checker at. If a project's content directory or static-site structure isn't already known (route resolution in the script assumes a Next.js `src/app` layout — a true Hugo/Jekyll/Docusaurus project needs its own route-discovery logic), say so and adapt or ask rather than guessing blindly. Don't assume "the Hugo blog" means any specific repo — verify the path exists first.

**1. Generate or accept the draft.** If drafting new content, follow `blog-proposal`'s voice rules and the anti-vibe rule: no invented links, installation steps, stats, images, or testimonials. If a claim can't be sourced from the repo, existing docs, or something Keith stated, either cite it for real or drop/hedge it — never paper over the gap with a plausible-sounding placeholder.

**2. Run the deterministic checker.**
```
pwsh -File C:\Sysadmin\KeithsWebsite\tools\Test-BlogContent.ps1 -ContentPath <dir> -RepoRoot <repo root> -OutputJsonPath <path>
```
Read the JSON. Per post you get `LinkChecks[]`, `ImageChecks[]`, `CodeChecks[]`, each with `Status` (`PASS`/`FAIL`/`SKIPPED`/`SKIPPED-DANGEROUS`/`NOT-EXECUTABLE`/`TIMEOUT`) and a `Detail` string.

**3. Judge the flagged items — don't take the script's "intended error" guess at face value.** The checker flags a code block as FAIL when it errors without nearby "fail/throw/error" language in the preceding ~300 characters, and *also* flags PASS-but-suspicious blocks where that language appears nearby but nothing actually failed. That proximity heuristic has a known false-positive mode: a bullet-point outline near the top of a post ("what you'll learn: ... making a mock throw to simulate failure...") can trip the "intended failure" match for an unrelated, earlier, successfully-passing example. Before accepting any `CodeChecks` FAIL as a real bug:
   - Re-read the **whole post**, not the 300-char window, to see whether *that specific block* is the one being described as a failure demonstration.
   - If the flag is a false match (the language belongs to a different section), that block is really a PASS — note the override and why.
   - If it's a real unsignposted error, this is an actual bug in the post: either fix the code so it does what the prose claims, or fix the prose to match what the code actually does. Never rewrite just to make the checker quiet without changing what's actually broken.
   - Recommend the post add an explicit ` ```powershell {expect-error}` info-string marker (or one sentence directly above the block: "this example is expected to throw") going forward, so this ambiguity stops being a heuristic guess.

   Run the same "did I actually verify this, or did I infer it" discipline on:
   - **Fabricated claims / stats.** Flag any specific number, version, benchmark, or external fact that isn't backed by a link, a repo file, or something Keith has told you directly. Do not invent a citation to resolve the flag — either find the real source or the claim gets hedged/removed.
   - **Voice authenticity.** Score 0–100 against 2–3 already-published posts from the same series/site as the baseline (pastoral-trained-communicator, technical-but-accessible, anti-vibe, calm/dry — not breathy hype; see `blog-proposal`'s Voice rules). Note specific lines that miss the mark, not just a number.
   - **Audience routing.** Check the title + tags/frontmatter state *who the post is for* specifically enough to route it (per `blog-proposal` voice rule 8). A generic title ("Testing best practices") gets flagged with a proposed specific retitle; this is a flag in the report, not a hard fail — Keith decides the final title.

**4. Rewrite-and-recheck loop.** Threshold to pass: zero unresolved link/image/code FAILs (after the judgment pass in step 3) **and** voice score ≥ 80 **and** zero unresolved fabrication flags. If anything's below threshold, rewrite only the specific offending section — not the whole post — then go back to step 2. Cap at **3 rewrite attempts per post**. If it still doesn't pass after 3 attempts, stop rewriting and mark it `HELD` with the exact unresolved reason(s); don't force a pass and don't keep looping silently.

**5. Report.** A markdown table, one row per post attempted:

| Post | Link Status | Image Status | Code Status | Voice Score | Result |
|---|---|---|---|---|---|

Passing posts get `Result = PASS` and are the ones "presented" as ready. Posts that hit the retry cap get `Result = HELD` with the specific reason in a note below the table — never silently omitted. Never claim a post is done without having actually re-run step 2 after the last rewrite; a rewrite that hasn't been re-checked is not a pass.

## Safety notes

- The checker's deny-list (`$script:DangerousPatterns` in `Test-BlogContent.ps1`) skips execution of anything that looks destructive (recursive deletes, force-pushes, `Format-Volume`, registry writes, etc.) and marks it `SKIPPED-DANGEROUS` rather than running it. If a post's example genuinely needs one of these patterns illustrated, don't loosen the deny-list to make it execute — describe why it's skipped in the report and let a human eyeball that specific block.
- All code execution runs in a fresh temp directory (`$env:TEMP\blog-audit-<guid>`) that's deleted afterward — never in the repo working tree.
- This pipeline never publishes, deploys, or pushes. It produces a report and (optionally) rewritten drafts sitting in the content directory. Publishing is Keith's explicit, separate call.

## What this does NOT do

- Does not invent facts, links, images, or citations to resolve a flag — an honest gap beats a fabricated fix.
- Does not accept the deterministic checker's "intended error" guess without re-reading full post context.
- Does not auto-publish or auto-deploy.
- Does not loop indefinitely on a failing post — 3 attempts, then `HELD` with a reason.
- Does not assume every project's content directory follows KeithsWebsite's Next.js route layout — adapt or flag before running against a differently-structured site.
