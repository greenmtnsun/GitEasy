---
name: security-sibling-sweep
description: Use when a security review (any of Keith's PowerShell suite projects) has identified a regex-based URL/host/path/credential parse finding and is about to declare it closed. Before closing, fan out across the codebase for sibling expressions of the same root cause — CWE-200/22/78/532-style root causes almost never live in exactly one file. Triggers on phrases like "the fix is to replace pattern X", "F-NN is closed", "marking this finding fixed", "this only affects function Y", or any virtual-security-reviewer turn where a single-location fix is about to be declared complete. Pairs with virtual-security-reviewer (the persona that does the review), verify-claims-on-disk (the trust-but-verify on fix-apply claims), and the GitEasy SECURITY-FINDINGS-2026-05-20.md artifact which encodes the project-level lesson.
---

> See also: `virtual-security-reviewer` for the adversarial-review framing, `verify-claims-on-disk` for trust-but-verify on apply claims.

# Security Sibling-Sweep

When a security review finds a regex-based parse bug (URL, host, path, credential, env-var) in one location, **before declaring the finding closed**, fan out across the codebase for sibling expressions of the same root cause. CWE-200/22/78/532-class root causes almost never live in exactly one file.

Skipping the sweep gives a fix that looks complete and leaves a recurrence-prone surface. Real cost when skipped: GitEasy 1.5.1 had to be effectively retired (not published to PSGallery) and a 1.5.2 cut for F-04/F-05/F-06 — three sibling findings the original F-01/F-02/F-03 pass missed.

## When this skill activates

Any of:

- A virtual-security-reviewer turn just identified a regex-based parse finding (`^https://(?<Host>[^/]+)/`, `[^/]+@`, `.*\.git/config`, or similar).
- The proposed fix is "replace pattern X with `[uri]` parse" / "use `[System.IO.Path]::GetFullPath`" / "use `ConvertFrom-StringData` with bounded keys" / any structured-parser-for-regex swap.
- The conversation contains *"the finding is closed"* / *"F-NN is fixed"* / *"only affects function Y"* / *"this is the only place that does X"* — before that claim is built upon.
- A PR / release tag is about to be cut and a security review was part of the pre-flight.

## The four-step protocol

Before any "finding closed" claim, all four steps must run and return either zero hits OR hits already covered by the proposed fix.

### Step 1 — Sweep for the pattern shape itself

Grep the whole repo (and ideally the whole Module Suite) for the **regex pattern** that produced the bug, or its key fragments. Examples:

```powershell
# If the F-02 fix replaced ^https://(?<Host>[^/]+)/ — sweep for the shape, not just the literal:
Grep -pattern '\^https://\(\?<' -type ps1
Grep -pattern '\[\^/\]\+' -type ps1
Grep -pattern '\[\^@\]\+@' -type ps1   # SSH-style sibling
```

The goal is fragment-level matching, not exact-string matching. Greedy character-class captures (`[^/]+`, `[^@]+`, `.*?`) are the most common shape — sweep for the *idiom*, not the *instance*.

### Step 2 — Sweep for other consumers of the same input type

Identify what *type of input* the bug consumed (a URL from `.git/config`, a host from an env var, a path from user param), then grep for every other place that input enters the codebase.

```powershell
# Example: F-02 was a URL read from .git/config. Sweep for every other reader:
Grep -pattern '\.git[/\\]config' -type ps1
Grep -pattern 'git config --get remote' -type ps1
Grep -pattern 'GetRemote|Get-Remote|RemoteUrl|remote_url' -type ps1
```

This is the highest-yield step. The same untrusted input often enters through three or four call paths; fixing one and missing the others is the canonical sibling-sweep miss. Test-Login in GitEasy 1.5.1 was a sibling read-path of Show-Remote that the original pass didn't sweep for.

### Step 3 — Sweep for every output / display / log / thrown-error boundary

The data that produced the finding probably surfaces in more places than the one being fixed. Log step headers, error messages, telemetry stamps, `Write-Verbose`, `Write-Host`, exception `Message` properties — every output surface is a potential leak point.

```powershell
Grep -pattern 'Write-(Verbose|Host|Information|Warning).*\$url' -type ps1
Grep -pattern 'throw .*\$host' -type ps1
Grep -pattern 'Invoke-GEGit.*log step' -type ps1   # F-06 lesson
```

F-06 in GitEasy was a log step header — neither a read path (step 2) nor a regex pattern (step 1). The output-boundary sweep is what catches it.

### Step 4 — Cross-suite sweep (when the shape is generic)

If the regex idiom or input type appears in more than one suite project, run steps 1–3 across the suite, not just the project under review. Greedy URL captures, `.git/config` parsing, plaintext-credential surfaces, path-traversal-vulnerable `-Path` parameters — these are suite-wide patterns. The cross-suite CWE-8 table in `virtual-security-reviewer` is the starting point for "what's generic."

```powershell
# Example: sweep all four suite repos for the same regex shape
foreach ($repo in 'GitEasy','WikiEngine','PesterForge','SqlBackupValidation') {
    Grep -pattern '\^https://\(\?<' -path "C:\Sysadmin\Scripts\$repo"
}
```

If a sibling is found in another suite project, escalate — it's a suite-level finding, not a project-level one, and the original project's release decision may need to wait.

## How to fan this out efficiently

Steps 1–3 are independent reads on the same codebase. Run them as **three parallel `Grep` calls in one tool-use block**, then synthesize. Step 4, if applicable, is N independent project sweeps — also parallel. Do not run sequentially; the cost framing below is built on parallelism.

For very large sweeps (whole suite, deep history), spawn an Explore sub-agent with a tight prompt: *"For each of these patterns [list], return file:line hits across these paths [list], grouped by pattern. No analysis, just the hits."* Bounded read-only output is exactly what Explore is good at.

## Declaring the finding closed

A finding may be declared closed when **all** are true:

1. The original location is fixed and the fix is verified on disk (per `verify-claims-on-disk`).
2. Step 1 (pattern sweep) returns zero hits, OR every hit is covered by the same fix.
3. Step 2 (input-consumer sweep) returns zero hits, OR every consumer is fixed.
4. Step 3 (output-boundary sweep) returns zero hits, OR every output path is sanitized.
5. Step 4 (cross-suite sweep) is either not applicable OR returns zero hits.

If any step returns uncovered hits, the finding is **not** closed. Open sub-findings for each, with the same fix discipline applied. The release tag (if one is pending) does not ship until all sub-findings close.

## Common failure modes the protocol catches

- **Sibling caller missed.** Two functions read the same `.git/config` URL; the first was reviewed, the second wasn't named in the scope. (Test-Login vs Show-Remote in GitEasy 1.5.1.)
- **Output-surface missed.** The read path was fixed but the same data is logged elsewhere through a header / verbose / error message. (F-06 in GitEasy 1.5.1.)
- **Generic idiom recurrence.** The greedy regex was fixed in one file; the same idiom exists in a third file that uses a different variable name. (Convert-GERemoteToSsh in GitEasy 1.5.1.)
- **Cross-suite recurrence.** The fix lands in GitEasy; the same shape sits unfixed in WikiEngine or PesterForge. (Not yet observed, but the CWE-8 table predicts it.)
- **Stale-scope review.** The review was scoped to "the three functions named in the original report" — siblings outside that scope were not reviewed because they were not asked about.

## What this skill is NOT

- Not a substitute for the original adversarial review (that's `virtual-security-reviewer`).
- Not a substitute for verifying the fix landed on disk (that's `verify-claims-on-disk`).
- Not a fuzzer or dynamic-analysis tool — purely a structural-grep sweep over source.
- Not a license to delay shipping for cosmetic similarity. A sibling-sweep hit only matters if it shares the same root cause; superficially similar regexes that operate on trusted input are not findings.

## Cost framing

- **Cost of running the sweep:** 3–4 parallel `Grep` calls per finding, ~5–10 seconds, no state changes. If the sub-agent route is taken: one Explore invocation.
- **Cost of skipping the sweep:** the 1.5.1 → 1.5.2 retirement cycle — a tag pulled from PSGallery (or never published), a follow-up release cut, and the reputational risk of "known-leaky code in the wild between the two releases." Both 7-day incidents (verify-claims-on-disk) plus the F-04/F-05/F-06 miss came from the same shape of under-scoped trust: *"I covered the case I was asked about, not the case the bug actually is."*

When a security review names a single finding location, assume there are more. The sweep is the discipline that proves the assumption wrong (good — single finding) or right (better — caught now, not in 1.5.1.5).
