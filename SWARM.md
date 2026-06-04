# GitEasy — Swarm Runbook

How to safely point multiple agents at this repository in parallel.

## Parallelizable

Work that fans out safely — each item is an independent file:

- **Per-function unit tests**: one agent per untested function writes a test in `Tests/Unit/`.
- **Steps: blueprint authoring**: one agent per function adds its CBH `Steps:` block; each `.ps1` is independent.
- **Read-only analysis**: code review, `tools/Audit-PublicJargon.ps1`, PSSA scan — any number of agents.
- **Per-command documentation review**: one agent per public command in `Public/`.

## Serial-only (never parallelize)

- **`GitEasy.psd1`** — module manifest; `FunctionsToExport` and `ModuleVersion` must be touched by one agent at a time.
- **`GitEasy.psm1`** — the dot-source loader; an edit here blocks module load for all concurrent agents.
- **`CHANGELOG.md`** — append-only; simultaneous appends produce merge conflicts.
- **Integration test runs that call `Save-Work`** — `Tests/GitEasy.*.Tests.ps1` create and destroy temp repos; run them serially, not in parallel within one process. CI already handles this correctly.

## Isolation

Use a git worktree (`isolation: 'worktree'`) when an agent:

- Edits multiple files in `Public/` or `Private/` in a single pass.
- Runs the full integration suite (`Tests/GitEasy.*.Tests.ps1`).

Read-only agents (grep, read, analysis) do NOT need worktrees.

## Claim-before-work

Before writing to any source file:

1. Read `SWARM-CLAIMS.md` at the project root (if it exists) for an `IN-PROGRESS` entry on that file.
2. If unclaimed, append a row: `| <file> | IN-PROGRESS | <session-id> | <UTC timestamp> |`
3. On completion, update the row to `DONE`.

A file with an `IN-PROGRESS` entry from a live session is off-limits. A claim older than 30 minutes with no update is considered stale and may be overridden.

## Verification gates

Every agent must clear all four before claiming a task done:

1. **AST parse clean**
   ```powershell
   $errors = $null
   [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$errors)
   $errors.Count -eq 0
   ```

2. **Checker green** — 0 new HARD violations:
   ```powershell
   pwsh -File "C:\Users\keith\.claude\skills\swarm-ready\Test-StepBlueprint.ps1" -ProjectRoot "C:\Sysadmin\Scripts\GitEasy"
   # Must stay at 0 HARD
   ```

3. **Pester green** — the unit test for this function still passes:
   ```powershell
   Invoke-Pester -Path "Tests\Unit\<FunctionName>.Tests.ps1" -PassThru
   # Zero failures
   ```

4. **PSSA clean** — no new violations introduced:
   ```powershell
   Invoke-ScriptAnalyzer -Path $filePath -Settings PSScriptAnalyzerSettings.psd1
   # Pre-existing suppressions are exempt; new violations are a gate failure
   ```
