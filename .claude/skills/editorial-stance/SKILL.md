---
name: editorial-stance
description: Use when modifying any renderer that emits documentation harvested from PowerShell metadata (Markdown, Confluence storage format, future MCP / second-language renderers), or when evaluating proposals that would have the engine fabricate, infer, or "fill in" sparse content. Encodes the anti-vibe rule that is load-bearing across the Module Suite — honest gaps over plausible-sounding fabrication. Three behaviors are machine-verified by Pester (NfU on empty Description, Synopsis suppression, empty Examples suppression).
---

> See also: `software-creation` §10 (vibe content listed in anti-patterns). `module-suite` for cross-product strategy and the editorial-stance summary line.

# Editorial stance — anti-vibe

The Module Suite's renderers feed a public documentation site. Its value rests on one editorial choice: **honest gaps over fabricated content.** Every other PowerShell-docs site reposts Microsoft Learn or pads gaps with LLM noise. Keith's bet is that a smaller honest reference beats a larger plausible-sounding one.

This rule is **machine-verified**, not aspirational. ~30 Pester tests in `C:\Sysadmin\Scripts\WikiEngine\Confluence\ConfluenceStorage.Tests.ps1` pin the three suppression behaviors below. A regression breaks the build.

The rule applies to *harvested third-party content* — module metadata Keith doesn't own. It does not constrain Keith's own comment-based help in his own modules; that's first-party content.

---

## The three rules

### 1. Empty Description → "Note for Users" admonition

When a command's harvested `Description` is blank, whitespace, or absent, the renderer emits a labeled admonition stating the upstream module shipped without comment-based help. **Never** AI-author a description.

Markdown form (the working text — exact wording lives in the renderer):

```markdown
> **Note for Users:** This command's upstream author did not include a description.
> The information shown here is harvested from PowerShell's reflection metadata; no
> hand-written description was available to render.
```

Confluence storage format: render the same content inside an `info` macro so the gap is visually distinct from authored prose:

```xml
<ac:structured-macro ac:name="info">
  <ac:rich-text-body><p>Note for Users: …</p></ac:rich-text-body>
</ac:structured-macro>
```

Future renderers (MCP output, second-language renderers) carry the same admonition in whatever form is idiomatic for that target.

### 2. Synopsis missing or duplicated → suppress the section

If `Synopsis` is absent, or if it's identical to `Description` (a common publisher anti-pattern of repeating the description), suppress the Synopsis section entirely. Don't fabricate a shorter version, don't truncate the description.

### 3. Empty Examples → suppress the section

When `.EXAMPLE` blocks are absent or all whitespace, suppress the Examples section. Don't auto-generate placeholder examples like `Get-Thing -X 'foo'`. A wrong example is worse than no example. (Keith has named this as a personal pain point — bad `.EXAMPLE` blocks were the reason he gave up on competing tools.)

---

## When this skill triggers

- Authoring or modifying a renderer (Markdown emitter, Confluence storage emitter, future MCP / second-language renderers)
- Proposals to "enrich" sparse content via AI, heuristics, or pattern-inference
- Schema changes that affect what a renderer emits (new field, optional field handling)
- Adding a renderer for a new output format
- Code review of any function that emits documentation strings into the public site
- Anyone suggesting "let's just have the LLM fill it in"

## What this skill does at trigger

1. **Identify which of the three rules applies.**
2. **Verify the renderer matches.** The pinned contract is in `WikiEngine\Confluence\ConfluenceStorage.Tests.ps1` — read the relevant test before changing behavior.
3. **If the proposal would weaken any rule, push back before doing it.** Cite which rule and why it's load-bearing.
4. **For a new renderer, port all three rules** — same behaviors across every output format.
5. **For a schema field addition with rendering implications, name the empty-state contract** in the same change (what does the renderer do when this field is blank? Suppress, NfU, or render-as-given).

## What this skill does NOT do

- Does not apply to internal private helpers — no public surface, no editorial concern.
- Does not apply to first-party CBH in Keith's own modules. That's content he owns; he's free to edit it.
- Is not the same rule as `software-creation` §5 (plain-English public command surface). That rule governs *command names and parameter labels*; this rule governs *rendered documentation content*. Related, distinct.

## Historical exception — SqlSpnManager

`SqlSpnManager`'s six wiki pages were authored before the stance was locked in. They carry `"Author": "Rogue AI Synthesis"` provenance. **Don't blindly re-render** — it's a flagged decision: keep with provenance disclosure / regenerate honestly / hand-author. Confirm disposition before touching those pages.

## Why "honest gaps" beats "AI fill"

When tempted to fill in a sparse page, stop. The sparseness *is* the signal: it tells the reader the upstream author shipped without docs, which is information the reader needs. A page that looks complete but was AI-padded misleads silently — the reader can't tell which paragraphs are real and which are plausible. The NfU admonition turns the gap into honest signal: visible, labeled, easy to scan past.

This is the moat. Don't undermine it for surface polish.
