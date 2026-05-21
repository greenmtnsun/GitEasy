# PSGallery Metadata Playbook — GitEasy

Pre-publish reference for filling every Gallery-surfaced metadata field
with deliberate, world-class content. Scope: the next `Publish-Module`
(1.5.2 or later). Internal planning material — direct, no hedging.

Canonical reference: [Package metadata values that impact the PowerShell
Gallery UI](https://learn.microsoft.com/en-us/powershell/gallery/concepts/package-manifest-affecting-ui?view=powershellget-3.x).
Where it is silent, supplemental Learn pages are cited per section.

## Every Gallery field, with what populates it

| Gallery section | `.psd1` source / external file | Current GitEasy value | Recommended value |
|---|---|---|---|
| Page title (`<ModuleName> <Version>`) | Filename + `ModuleVersion` | `GitEasy 1.5.2` | Keep. Bump per SemVer; never reuse a published version (Gallery enforces). |
| **Description** (large block under title) | `Description` (root) | "Plain-English Git workflow for PowerShell. Classic GitEasy public commands with a safer engine, per-invocation diagnostic logs, and no jargon in the user surface." | Rewrite to a 2-3 sentence pitch naming audience + differentiator (see Author/Owner section below). Search ranks Description content — put search phrases here, **not** as tags (per Learn: "if there's a phrase users will search for, add it to the package description"). |
| **Authors** (left sidebar) | `Author` (root) | `Keith Ramsey` | Keep. Single human name is normal. |
| **Owners** (left sidebar, links to PSGallery account) | Gallery account that ran `Publish-Module` — **not in the manifest** | (n/a — unpublished) | Will be the PSGallery account name. Owner is Gallery-side state, lost if package is copied between systems ([Learn FAQs](https://learn.microsoft.com/en-us/powershell/gallery/faqs?view=powershellget-3.x)). |
| **Copyright** (left sidebar) | `Copyright` (root) | "(c) Keith Ramsey. Licensed under the Mozilla Public License 2.0." | Tighten to `(c) 2026 Keith Ramsey. Licensed under MPL-2.0.` — year + SPDX identifier. |
| **Company** | `CompanyName` (root) | `Keith Ramsey` | Keep until a legal entity exists. Do **not** invent a company name. |
| **Project Site** (left sidebar link) | `PrivateData.PSData.ProjectUri` | `https://github.com/greenmtnsun/GitEasy` | Keep. Verify reachable at publish time. |
| **License Info** (left sidebar link) | `PrivateData.PSData.LicenseUri` | `https://www.mozilla.org/MPL/2.0/` | Switch to in-repo file: `https://github.com/greenmtnsun/GitEasy/blob/main/LICENSE`. Ties the displayed license to the exact text shipped. |
| **Icon** (left sidebar thumbnail) | `PrivateData.PSData.IconUri` | (unset) | **Set this.** 85x85 PNG, transparent background, direct image link (not a webpage). |
| **Release Notes** (collapsible on main page) | `PrivateData.PSData.ReleaseNotes` | `'See https://github.com/.../CHANGELOG.md'` | **Replace with inline text.** PSGallery does **not** render Markdown ([PowerShellGallery #58](https://github.com/PowerShell/PowerShellGallery/issues/58)). A bare URL wastes the surface. Inline ~40-80 plaintext lines per the template. |
| **Tags** (sidebar bullets, drives Gallery search + `Find-Module -Tag`) | `PrivateData.PSData.Tags` | 8 tags (git, github, gitlab, sysadmin, plain-english, beginner-friendly, powershell, workflow) | Replace with 14-tag set below. Single-word case-insensitive; PascalCase / hyphens / underscores for readability. |
| **Prerelease** (badge; hides from default search) | `PrivateData.PSData.Prerelease` | (unset) | Leave unset for stable. SemVer v1 format `^[0-9A-Za-z-]+$`, e.g. `'rc1'`, only when ModuleVersion is 3 segments ([Learn](https://learn.microsoft.com/en-us/powershell/gallery/concepts/module-prerelease-support?view=powershellget-3.x)). |
| **License Acceptance prompt** (install-time) | `PrivateData.PSData.RequireLicenseAcceptance` + LICENSE file + `LicenseUri` | (unset / `$false`) | Leave `$false`. MPL-2.0 does not require click-through; adds install friction with no legal benefit ([Learn](https://learn.microsoft.com/en-us/powershell/gallery/concepts/module-license-acceptance?view=powershellget-3.x)). |
| **External Module Dependencies** (informational) | `PrivateData.PSData.ExternalModuleDependencies` | (unset) | Leave unset. Informational only. |
| **Dependencies** (resolved from `RequiredModules`) | `RequiredModules` (root) | (unset) | Leave unset — GitEasy has zero runtime module deps. |
| **Cmdlets** (collapsible) | `CmdletsToExport` | `@()` | Keep empty. Script module ships no compiled cmdlets. |
| **Functions** (collapsible, most-clicked) | `FunctionsToExport` | 20 explicit entries | Keep explicit. Wildcards (`'*'`) hurt load time and Gallery surface. Update with every public-surface change. |
| **DSC Resources** | `DscResourcesToExport` | (unset) | Leave unset. |
| **PowerShell Editions / min version** (badge or filter) | `PowerShellVersion`, `CompatiblePSEditions` | `'5.1'`, no `CompatiblePSEditions` | Add `CompatiblePSEditions = @('Desktop','Core')` once CI evidence is current (you have it — 522 on PS 5.1 + PS 7). Add `PSEdition_Desktop` and `PSEdition_Core` to Tags too — these power `Find-Module -Tag PSEdition_Core` ([Learn](https://learn.microsoft.com/en-us/powershell/gallery/concepts/module-psedition-support?view=powershellget-3.x)). |
| **Required PowerShell** (badge) | `PowerShellVersion` | `'5.1'` | Keep. |
| **File List** ("Show all" on package page) | Built from packaged contents — **not** from manifest `FileList` key | (will show everything packaged) | Exclude `Tests\`, `Wiki\`, `tools\Build-*`, `.claude\`, `.github\`, `docs\Goals\`, `docs\strategy\`, security findings docs from the published `.nupkg`. `FileList` manifest key is informational only ([about_Module_Manifests](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_module_manifests?view=powershell-7.5)). |
| **Version History** (table) | Auto — every prior published version | (n/a) | Populates from v2 onward. |
| **Date Published** | Auto | (n/a) | Auto. |
| **GUID** (sidebar / API only) | `GUID` (root) | `2e113abf-c0e7-4dfb-9cb1-69476d7541f6` | **Never change** for the life of the package. |
| **Online help URI** (per-function `Get-Help -Online`) | Per-function `.LINK` in CBH, **and/or** `HelpInfoURI` (root) | per-function CBH `.LINK` partial; `HelpInfoURI` unset | Add `.LINK https://github.com/greenmtnsun/GitEasy/wiki/Public-<Command>` in each public function CBH. Skip `HelpInfoURI` unless you actually publish HelpInfo XML for `Update-Help`. |

### `Get-Help` integration

The Gallery does **not** render CBH. The Functions collapsible lists
names only. The pitch for each command must live on (a) the README at
ProjectUri and (b) `Get-Help <Cmd> -Full` after install. The per-function
`.LINK` is the only Gallery-visible per-command deep link.

`CmdletsToExport` is for binary modules (C# cmdlets). GitEasy is a
script module — all 20 public commands go in `FunctionsToExport`.
Current state correct.

## Proposed tag list

14 tags. Single-word, case-insensitive, no spaces. Long phrases go in
Description (Learn guidance).

- **`Git`** — primary keyword.
- **`GitHub`** — explicit HTTPS PAT + SSH support for github.com.
- **`GitLab`** — same auth surface; keep.
- **`Bitbucket`** — third-tier provider, same auth surface; cheap to add.
- **`SourceControl`** — generic discovery term (ops vocabulary).
- **`VersionControl`** — engineer vocabulary; intentionally a second tag because the search behaviors diverge.
- **`Sysadmin`** — primary persona; keep.
- **`DevOps`** — adjacent persona; pulls in CI/CD audience.
- **`Automation`** — high-volume Gallery search term.
- **`Workflow`** — keep, matches Description framing.
- **`Plain-English`** — the differentiator. Brand-like tag for return visitors.
- **`Beginner-Friendly`** — secondary differentiator; keep.
- **`PSEdition_Desktop`** — required for `Find-Module -Tag PSEdition_Desktop`.
- **`PSEdition_Core`** — only add once `CompatiblePSEditions = @('Desktop','Core')` is stamped and you have CI evidence (you do).

Dropped: **`PowerShell`** — every module on the Gallery is PowerShell;
adds zero discoverability.

Phrases for **Description**, not Tags: "plain English wrapper around
git", "no Git jargon", "diagnostic logs for every command",
"credential-surface hardened", "for change managers and compliance
teams".

## Icon recommendation

Requirements (Learn UI page):

- **85x85 pixels**, square.
- **Transparent background** (PNG with alpha).
- **Direct image link** (not a webpage). Gallery renders
  `<img src="$IconUri">`; HTML targets show a broken thumbnail.

Concrete plan:

1. Create `C:\Sysadmin\Scripts\GitEasy\Assets\icon.png` (85x85,
   transparent). Optional `icon@2x.png` (170x170) for README.
2. Host via raw GitHub:
   `https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/Assets/icon.png`.
   This is the pattern dbatools, posh-git, PowerShellForGitHub all use.
3. Pin to `main` for low-friction icon refresh, or to a tag (`v1.5.2`)
   for immutability. Recommend `main` — re-publishing a manifest just
   to fix an icon is wasteful.
4. Concept: a clean monogram glyph (book/notebook silhouette +
   fork-branch arrow). **Not** a recolored git logo (trademark hazard).
   **Not** stock clip-art.

Manifest entry:
`IconUri = 'https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/Assets/icon.png'`.

Verify: `Invoke-WebRequest $IconUri -Method Head` → `200` +
`Content-Type: image/png`.

## Author / Owner / Company info

```powershell
Author      = 'Keith Ramsey'
CompanyName = 'Keith Ramsey'
Copyright   = '(c) 2026 Keith Ramsey. Licensed under MPL-2.0.'
Description = 'Plain-English Git for PowerShell. GitEasy gives sysadmins, change managers, and compliance teams a small set of jargon-free commands (Save-Work, Show-History, Set-Ssh, Reset-Login) that wrap git with a hardened engine, per-invocation diagnostic logs, and no raw git output on the user surface. Windows PowerShell 5.1 and PowerShell 7. MPL-2.0.'
```

Notes:

- **Description** is the most-read field after the title. Three jobs:
  name the audience (sysadmins / change managers / compliance), list
  command names so visitors recognize the shape, state the
  differentiator. Under 400 chars — longer gets truncated in
  search-results cards.
- **PSGallery account ("Owners")** — set up the publishing account as
  `greenmtnsun` to match the GitHub handle and ProjectUri. Mismatched
  handles look unprofessional.
- **No "Inc." or "LLC" until one exists.** Anti-vibe rule applies.

## Release notes template

PSGallery renders ReleaseNotes as **plaintext**, line-wrapped — no
Markdown ([PSGallery #58](https://github.com/PowerShell/PowerShellGallery/issues/58),
still open in 2026). No `**bold**`, no `[link](url)`, no fences. Bare
URLs work. Use dashes and indentation for structure.

No documented length cap. Observed convention (dbatools, Pester,
PSReadLine): 40-150 lines per release. The Gallery uses a "Show more"
expander past some threshold — stay <= 150 lines per release to be safe.

Paste-ready for 1.5.2 (drop between `@'` and `'@` in `ReleaseNotes`):

```
GitEasy 1.5.2 - 2026-05-20
==========================

Second adversarial pass after the 2026-05-17 credential-surface review.
522 tests on Pester 3.4.0, PS 5.1 + PS 7.

Security (CWE-200 / CWE-532)
----------------------------
- F-04 (High) - Set-Ssh HTTPS->SSH conversion no longer persists
  credential-embedded user-info from .git/config. Convert-GERemoteToSsh
  now parses with [uri] and refuses non-empty UserInfo.
- F-05 (Medium) - Test-Login return object and error message now route
  through Format-GESafeUrl. Format-GESafeUrl generalised to sanitise
  URLs that appear mid-string.
- F-06 (Medium) - Invoke-GEGit step header and thrown error no longer
  echo credential-bearing arguments. Every argument runs through
  Format-GESafeUrl (no-op on non-URL args) before being joined.

Correctness
-----------
- Reset-Login cmdkey path now checks each cmdkey exit code before
  flipping clearedSomething.
- Save-Work ModuleVersion regex now accepts single- or double-quoted
  version values.
- Set-Vault now opens a log session, returns a structured object on
  every path including -WhatIf.

Plain-English / no-jargon
-------------------------
- Show-Change comment-based help describes the -NextSave parameter
  (1.5.0 rename from -Staged left CBH stale).
- Search-History return property Hash renamed to Id.
- Format/GitEasy.format.ps1xml column labels Staged -> Ready,
  Unstaged -> Pending, Untracked -> New. Property names preserved.

Cross-platform
--------------
- Show-Diagnostic platform-detects before Start-Process explorer.exe
  / Start-Process $logFile. Non-Windows hosts get a path hint.

Full notes and trust-boundary trace:
https://github.com/greenmtnsun/GitEasy/blob/main/CHANGELOG.md
https://github.com/greenmtnsun/GitEasy/blob/main/docs/SECURITY-FINDINGS-2026-05-20.md
```

Future-release skeleton (trim sections that don't apply; lead with
audience-impact category — Security first if any):

```
GitEasy <version> - <YYYY-MM-DD>
================================
<1-2 sentence theme>.
<N> tests on Pester <ver>, PS 5.1 + PS 7.

Added
-----
- ...

Security
--------
- F-<n> (<severity>) - <root cause>. <fix>.

Fixed
-----
- ...

Changed
-------
- ...

Deprecated
----------
- ...

Removed
-------
- ...

Full notes:
https://github.com/greenmtnsun/GitEasy/blob/main/CHANGELOG.md
```

Style rules: one-line per bullet (if you need two, you have two
bullets); no emojis in the Gallery surface; never bury Security under
"Misc."

## Pre-publish checklist

Treat any unchecked item as a blocker.

**Manifest (`GitEasy.psd1`)**

- [ ] `ModuleVersion` bumped per SemVer; not already on PSGallery
  (`Find-Module GitEasy -RequiredVersion <v> -EA SilentlyContinue`
  returns nothing).
- [ ] `GUID` unchanged from `2e113abf-c0e7-4dfb-9cb1-69476d7541f6`.
- [ ] `Author`, `CompanyName`, `Copyright` match the recommended
  strings.
- [ ] `Description` matches recommended (or a deliberate update);
  under 400 chars; names audience + differentiator + 3+ command names.
- [ ] `PowerShellVersion = '5.1'`.
- [ ] `CompatiblePSEditions = @('Desktop','Core')` (only if last full
  Pester pass on both editions is THIS release).
- [ ] `FunctionsToExport` matches `Public\` directory exactly. No
  wildcards.
- [ ] `CmdletsToExport = @()`, `VariablesToExport = @()`,
  `AliasesToExport = @()` — empty arrays, not `'*'`.
- [ ] `PrivateData.PSData.Tags` = the 14-tag list.
- [ ] `PrivateData.PSData.LicenseUri` =
  `https://github.com/greenmtnsun/GitEasy/blob/main/LICENSE`.
- [ ] `PrivateData.PSData.ProjectUri` =
  `https://github.com/greenmtnsun/GitEasy`.
- [ ] `PrivateData.PSData.IconUri` set + verified (`HEAD 200` +
  `Content-Type: image/png`).
- [ ] `PrivateData.PSData.ReleaseNotes` = inline plaintext block, NOT a
  URL.
- [ ] `PrivateData.PSData.Prerelease` unset (or matches
  `^[0-9A-Za-z-]+$` for previews).
- [ ] `PrivateData.PSData.RequireLicenseAcceptance` unset / `$false`.

**Repo state**

- [ ] `LICENSE` exists at repo root, matches `Copyright` (MPL-2.0).
- [ ] `Assets\icon.png` exists, 85x85, transparent PNG.
- [ ] `README.md` opening 200 chars and manifest `Description` do not
  contradict.
- [ ] `CHANGELOG.md` has this version's entry; matches inline
  `ReleaseNotes`.
- [ ] `git tag v<version> && git push --tags`.

**Build / test gate**

- [ ] `Test-ModuleManifest .\GitEasy.psd1` clean.
- [ ] `Import-Module .\GitEasy.psd1 -Force` succeeds on PS 5.1 **and**
  PS 7.
- [ ] Pester green on both editions (current bar: 522 / 522).
- [ ] `Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error` empty.
- [ ] `Get-Command -Module GitEasy` lists exactly the 20
  `FunctionsToExport` entries.
- [ ] `Get-Help Save-Work -Online` opens the wiki page (proves `.LINK`
  wired).

**Package contents** (what ships in the `.nupkg`)

- [ ] Excluded: `Tests\`, `.github\`, `.claude\`, `.git\`, `Wiki\` (if
  not user-facing), `tools\Build-*.ps1`, `docs\Goals\`,
  `docs\strategy\`, `docs\SECURITY-FINDINGS-*.md`, `*.tmp`, `*.log`.
- [ ] Included: `GitEasy.psd1`, `GitEasy.psm1`, `Public\`, `Private\`,
  `Format\`, `LICENSE`, `README.md`, `CHANGELOG.md`, `Assets\icon.png`.
- [ ] Air-gap sentinel passes against the staged folder (no machine
  names, no domain prefixes, no IPv4).

**Publish**

- [ ] PSGallery API key from secrets store, not hardcoded.
- [ ] Dry run:
  `Publish-Module -Path <staged> -NuGetApiKey $apiKey -WhatIf`.
- [ ] Real run:
  `Publish-Module -Path <staged> -NuGetApiKey $apiKey`.
- [ ] Within 15 min:
  `Find-Module GitEasy -RequiredVersion <v>` returns it.
- [ ] Open
  `https://www.powershellgallery.com/packages/GitEasy/<v>`. Visual
  check: Description, Icon, ProjectUri/LicenseUri clickable, Tags
  match, Release Notes populated, 20 functions listed.
- [ ] Smoke test (clean session):
  `Install-Module GitEasy -Scope CurrentUser -Force;
  Import-Module GitEasy;
  (Get-Command -Module GitEasy).Count` returns 20.

**Post-publish**

- [ ] Note version in `Wiki\Roadmap.md`.
- [ ] If anything is wrong, **bump the version and re-publish** —
  PSGallery blocks republish of the same version.

## Gaps / open questions

1. **Exact ReleaseNotes truncation threshold.** Not documented. Stay
   <= ~150 lines per release.
2. **Markdown rendering in ReleaseNotes** — still plaintext only as
   of PowerShellGet 3.x
   ([#58](https://github.com/PowerShell/PowerShellGallery/issues/58)).
   If it ever lands, the plaintext template will still render
   correctly.
3. **`HelpInfoURI` worth setting?** Only if you actually publish
   HelpInfo XML + locale cab files for `Update-Help`. Skip until
   there's a reason.
4. **Ship `Wiki\` inside the package?** Recommend **no** — duplicates
   GitHub wiki, references break inside `$env:PSModulePath`. Point
   users to ProjectUri.
5. **PSGallery owner handle** — recommend `greenmtnsun` to match
   GitHub + ProjectUri. Set via the account that holds the API key;
   not a manifest field.
6. **LicenseUri: in-repo vs canonical Mozilla URL** — recommend in-repo
   (`/blob/main/LICENSE`) for anti-vibe alignment (display matches
   what shipped). Keith's call.
7. **`CompatiblePSEditions` claim** — CHANGELOG asserts PS 5.1 + PS 7
   pass. Re-verify on a clean machine before stamping the claim.
8. **`New-Release` in `FunctionsToExport`** — if it's a maintainer-only
   release-cutting helper, demote to `tools\` and remove from public
   surface. 5-minute decision before publish.

## Summary

**What I found.** Every Gallery-surfaced field maps to either a root
manifest key (`Author`, `Description`, `Copyright`,
`FunctionsToExport`, `PowerShellVersion`, `CompatiblePSEditions`), a
`PrivateData.PSData.*` entry (`Tags`, `LicenseUri`, `ProjectUri`,
`IconUri`, `ReleaseNotes`, `Prerelease`, `RequireLicenseAcceptance`,
`ExternalModuleDependencies`), or Gallery-side state (`Owners` = the
API-key account; `Version History`, `Date Published` = auto; File List
= package contents, not the `FileList` manifest key). Owners is
Gallery-only and is not part of the `.psd1`.

**Biggest current gaps in `GitEasy.psd1`.** No `IconUri` (set it —
85x85 transparent PNG at raw.githubusercontent.com); `ReleaseNotes` is
just a URL (PSGallery does not click — inline the plaintext per the
template); Tags miss `PSEdition_Desktop` / `PSEdition_Core` (which
drive the `Find-Module -Tag` filter) and miss `SourceControl` /
`VersionControl` / `DevOps` / `Automation` / `Bitbucket`;
`CompatiblePSEditions` should be stamped explicitly
(`@('Desktop','Core')`) since the test suite already runs green on
both. `LicenseUri` should point to the in-repo LICENSE rather than the
canonical Mozilla URL so the displayed license matches the shipped
text.

---

*Generated by the PSGallery research agent, 2026-05-21. Reconciled
against working tree at GitEasy 1.5.2.*
