# GitEasy — Decision Records, Phase 1 (Design)

Foundational design choices. Bootstrapped retroactively 2026-05-28: each DR
is sourced from a real artifact (cited in the **Source** field). Nothing
here is invented; the decisions were already made and shipped — this file
formally records them so future audits and contributors find them in one
place.

---

## DR-001
# Decision Record 001 — Plain-English public surface, no Git jargon

## Status
DECIDED (retroactive, ratified 2026-05-28; original choice ~v1.0.0).

## Question
Do GitEasy's public commands and the data they return use the standard Git
vocabulary (commit, stage, push, HEAD, ref, etc.), or do they use plain
English a non-developer reads without translation?

## Context
The README's "From Keith" section frames the entire product around relief
for non-developers — DBAs, change managers, compliance teams — who do not
want a new vocabulary. The public command names (`Save-Work`, `Show-History`,
`Find-CodeChange`, `Undo-Changes`) and the field rename in v1.5.2
(`Hash` → `Id` on `Search-History` output; `Staged` → `Ready` and
`Unstaged` → `Pending` on the format table) are the visible commitments.

## Decision
**Plain-English public surface.** Command names, parameter names, and
returned property labels stay in plain English. The internal engine is
free to use Git vocabulary. The jargon-audit tool (`tools/Audit-PublicJargon.ps1`)
enforces this on the public surface.

## Source
- README.md "From Keith"
- docs/HOW-TO-USE-GITEASY.md
- CHANGELOG 1.5.2 — Search-History `Hash` → `Id` rename
- tools/Audit-PublicJargon.ps1

## Phase
1

---

## DR-002
# Decision Record 002 — Private helpers use the `GE` prefix; public commands do not

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
Should every function in the module — public or private — carry a project
prefix, or only the private helpers?

## Context
Suite convention says private helpers carry a project prefix to avoid name
collision with similarly-named functions in other modules. GitEasy's public
commands are deliberately bare (`Save-Work`, not `Save-GEWork`) because the
plain-English public-surface decision (DR-001) treats the prefix as
developer-jargon noise.

## Decision
**Private helpers use the `GE` prefix; public commands do not.** This is the
"Immutable Rule" stated in PROJECT_MANIFEST.md.

## Source
- PROJECT_MANIFEST.md "Immutable Rules"
- Private/*.ps1 (every file follows the rule)
- Public/*.ps1 (no prefix)

## Phase
1

---

## DR-003
# Decision Record 003 — License is MPL-2.0; project survives independent of the author

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
What license does GitEasy ship under, and what does that mean for the
project if the author stops maintaining it?

## Context
The README's "From Keith" section is explicit: "GitEasy is licensed under
MPL 2.0, which means anyone is free to pick up the code and continue with
it on their own. The project's survival doesn't depend on me." MPL-2.0 is
also the value stamped into `Copyright` in the manifest as of v1.5.3.

## Decision
**MPL-2.0.** Survival-independent of the author is a design feature, not
an afterthought.

## Source
- LICENSE
- GitEasy.psd1 (Copyright)
- README.md "From Keith"

## Phase
1

---

## DR-004
# Decision Record 004 — PowerShell-only; no cross-language dependencies

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
May GitEasy depend on compiled binaries, Python, .NET libraries shipped
inside the package, or other non-PowerShell artifacts?

## Context
PROJECT_MANIFEST.md states "PowerShell only" as an Immutable Rule. The
audience is sysadmins and DBAs on Windows boxes; demanding a Python
install or a compiled DLL would defeat the relief-from-friction goal
(DR-001). System tools that already exist on Windows (`git.exe`,
`cmdkey.exe`) are call-out dependencies, not bundled dependencies.

## Decision
**PowerShell only.** No bundled binaries, no other-language runtimes. The
module calls `git.exe` (which the user must have installed) and is otherwise
self-contained.

## Source
- PROJECT_MANIFEST.md "Immutable Rules"
- GitEasy.psd1 (no RequiredAssemblies, no compiled deps)

## Phase
1

---

## DR-005
# Decision Record 005 — Structured-result return on every public command path

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
Should a public command always return a structured `[pscustomobject]` with
a known shape, including on `-WhatIf` paths and refusal paths, or may it
return `$null` / write to host / throw on those paths?

## Context
The v1.5.2 fix for `Set-Vault` explicitly named "previously returned `$null`
on `-WhatIf` decline (violating the structured-result contract)" as the
defect. That phrasing implies the rule was already in force; the fix
brought `Set-Vault` into line. The downstream consequence is that a
`$result.Status -eq 'Succeeded'` check works regardless of which path the
caller took.

## Decision
**Every public path returns a structured object with at least `Status` and
`Outcome` fields.** `-WhatIf`, refusal, and handled-error paths return the
same shape as success — only the field values change. Throws are reserved
for unrecoverable engine-level failures.

## Source
- CHANGELOG 1.5.2 — "Set-Vault.ps1 now uses the same log-session bracket as every other state-changing command"
- Public/*.ps1 (every command's return paths)

## Phase
1

---

## DR-006
# Decision Record 006 — One log file per invocation under `%LOCALAPPDATA%\GitEasy\Logs\`

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
Where does GitEasy write its logs, and what is the lifetime of a single log
file?

## Context
The CHANGELOG and CBH on `Save-Work` describe self-contained log files
per run with the path printed to the user on failure. `Get-GELogPath` and
`Start-GELogSession` / `Complete-GELogSession` / `Remove-GEOldLog` are the
private surface; `Show-Diagnostic` is the public entry point. The default
path is `%LOCALAPPDATA%\GitEasy\Logs\`, overridable per-command via
`-LogPath` or per-session via `$env:GITEASY_LOG_PATH`.

## Decision
**One log file per invocation, default `%LOCALAPPDATA%\GitEasy\Logs\`.**
Successful runs log silently; failures throw a plain-English message and
point at the log file. 30-day pruning runs via `Remove-GEOldLog`.

## Source
- docs/FOR-GIT-EXPERTS.md (override knobs)
- CHANGELOG references to log surface
- Private/Add-GELogStep.ps1 + Start-GELogSession.ps1 + Complete-GELogSession.ps1

## Phase
1

---

## DR-007
# Decision Record 007 — Vault-based credential storage; never embed credentials in remote URLs

## Status
DECIDED (retroactive, ratified 2026-05-28).

## Question
How does GitEasy store and pass credentials to `git`, given that
`https://user:token@host/path` style URLs work natively but leak the
credential anywhere the URL is logged?

## Context
The public commands `Set-Vault`, `Set-Token`, `Get-VaultStatus`, and
`Reset-Login` are the credential surface. The v1.5.1 / 1.5.2 security
sweep (F-01..F-06) closed sibling bugs that all came from the same
anti-pattern: credentials embedded in a remote URL being captured by a
regex parse and then echoed on a log / error / output path. The fix is
structural — credentials live in a vault, not in `.git/config`.

## Decision
**Vault-based credential storage.** Embedded-credential URLs are refused
on the write path (`Test-GERemoteUrlSafe`) and scrubbed on the read /
log / output path (`Format-GESafeUrl`, `Format-GESafeLogLine`). See DR-012
and DR-013 for the safety triad shipped in v1.5.2.

## Source
- Public/Set-Vault.ps1, Set-Token.ps1, Get-VaultStatus.ps1, Reset-Login.ps1
- docs/SECURITY-FINDINGS-2026-05-17.md, SECURITY-FINDINGS-2026-05-20.md
- CHANGELOG 1.5.1, 1.5.2

## Phase
1
