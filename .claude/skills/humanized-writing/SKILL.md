---
name: humanized-writing
description: Use whenever producing English prose a human will read, in any project — blog posts, documentation, help files, specs, READMEs, marketing copy, emails, announcements, release notes, web copy, wiki pages, store listings. Two-pass pipeline that strips AI writing tells (pass 1 rules + self-audit) and then lints mechanically with Vale + Microsoft Writing Style Guide (pass 2). Covers ALL English prose deliverables, technical reference included (Keith's call, 2026-08-03). Trigger generously — the failure mode is NOT triggering.
---

# Humanized writing — two-pass pipeline

Origin: the 2026-08-01 DetentShell incident — a 24-post blog series written *trying* to
sound human still read as "obviously AI generated" (Keith's words, and he was right).
Good intent does not prevent the tells; only explicit rules checked against the text do.
The rules below distill the tooling consensus (all of it derives from Wikipedia's
"Signs of AI writing" catalog — there is no competing school to arbitrate).

**The standing register rule ("let your yes be yes") lives in global CLAUDE.md §10 —
that paragraph is its one home. This skill applies it; it does not restate it.**

## Pass 1 — write under these rules

Hard bans:

- Negative parallelism: "not just X, but Y" / "That's not A. That's B."
- Rule-of-three lists built for rhythm rather than because there are three things.
- More than one em dash per paragraph.
- Engineered aphorism endings — the kicker/mic-drop closer ("We ship questions.").
  End when the information ends.
- Bold lead-ins on list items ("**Name.** Text…").
- Fancy copulas ("serves as", "boasts", "stands as") where is/has works.
- Fake-significance vocabulary: pivotal, testament, underscores, crucial.
- The AI wordlist: delve, tapestry, landscape, leverage, robust, vibrant, showcase,
  foster, intricate, meticulous, seamless, elevate, empower, unlock, journey.
- Trailing present-participle commentary ("…, highlighting the importance of X").
- Meta/collaborative talk: "Here's the thing", "worth noting", "let's", rhetorical-question
  openers.
- Vague attribution ("experts agree", "many developers find").
- Elegant variation — synonym-cycling to avoid repeating a word. Repeating a word is human.
- Honesty narration and certifying flourishes — see CLAUDE.md §10 (yes-be-yes).

Requirements:

- Sentence-case titles, varied in form and length across a series. Uniformly clever
  titles are themselves a tell — that is specifically what Keith caught.
- Varied sentence and paragraph rhythm; fragments and contractions allowed.
- Specifics over adjectives: numbers, filenames, exact strings.
- Facts only — no invented users, anecdotes, or composite stories (pairs with
  `editorial-stance` and `honest-completion`; reference them, don't duplicate).

Self-audit before delivering: scan your own draft against the ban list, rewrite hits,
check the ending isn't a kicker, check title variance if it's a series.

## Pass 2 — Vale, mechanically

Run Vale on every prose file before calling it done, and rewrite until the real
findings are gone (house-style divergences are already configured off):

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\errata-ai.Vale_Microsoft.Winget.Source_8wekyb3d8bbwe\vale.exe" --output=line <file.md>
```

Config resolution: a repo-local `.vale.ini` wins when present (PS7-ISE's is the
per-project example, with a project vocabulary at
`.vale\styles\config\vocabularies\DetentShell\accept.txt` to silence domain-term
noise); otherwise the global `C:\Users\keith\.vale.ini` applies (styles in
`.vale\styles-clean`, hash-verified Microsoft package). A PostToolUse hook also runs
Vale automatically on markdown writes — the hook is the net; this pass is the
discipline. Judgment applies to Vale suggestions: fix real findings, and when a
finding fights an established house register, silence it in the repo's `.vale.ini`
with a comment rather than ignoring it silently.

## Calibration — the actual failure counts from the incident

All 24 posts ended on an engineered aphorism; negative parallelism in nearly every
post; 3-5 em dashes per paragraph; bold lead-in paragraphs; every title a matching
3-6-word clever phrase; meta-commentary throughout. The worked before/after corpus
is `git diff edf7c19 7d79141 -- docs/blog/` in the PS7-ISE repo — 24 real documents,
tell → fixed.

## Interactions

- `blog-proposal` / `blog-content-pipeline`: those skills' style guidance defers here.
- The `ᵃⁱ` marker convention (flagging AI-vibe filler to Keith) still applies during
  drafting; this skill exists so there is nothing left to mark.
- PS7-ISE `docs/blog/STYLE.md` predates this skill and should point here as canonical
  (queued back to the PS7-ISE session).
