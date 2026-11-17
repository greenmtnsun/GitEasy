---
name: provenance-stamping
description: Use when authoring or modifying any public command that returns data in Keith's suite projects. Lean toward stamping every result with provenance — module version, schema revision, commit SHA when available, run id, timestamp — so a downstream user can prove which version of which command produced which answer. Reproducibility moves the suite from "scripts that work" to "tools enterprise buyers trust." Pairs with function-design (the result shape) and air-gap-discipline (no host-name leakage in the stamp).
---

> See also: `function-design` for the public-surface result shape. `software-creation` §4 for the structured-result contract. `air-gap-discipline` for the no-host-name rule the stamp must respect. `module-suite` for the JSON schema this nests inside.

# Provenance stamping — the reproducibility moat

Most PowerShell modules return data and call it done. The user gets numbers, but no way to prove which version of the tool produced them, against which schema, on which commit. When that user is an auditor, a regulator, or a customer reproducing a finding six months later, the gap matters.

This skill encodes the rule that **lean toward stamping every public command's result with provenance.** It is not yet a hard line (some commands are too lightweight to bother), but it is the suite's distinctive bar.

## What goes into a provenance stamp

A `Provenance` field on the structured result, populated with the values that are knowable at runtime:

```powershell
$stamp = Get-SbvProvenance -CommandName $MyInvocation.MyCommand.Name -SchemaRevision '1.0'

return [pscustomobject]@{
    Status        = 'Succeeded'
    Outcome       = "Validated 47 backups across 3 instances"
    ErrorCategory = 'None'

    # function-specific result data
    BackupCount   = 47
    InstanceCount = 3

    # provenance stamp (helper defined below; null-safe)
    Provenance    = $stamp
}
```

**Stamp on success and failure paths both.** The structured-result rule (per `software-creation` §4) says every return path returns a result — provenance follows the same rule. An auditor reviewing a `HandledError` result needs the same provenance as a `Succeeded` result.

**Required fields** (when the stamp is present):

- `Command` — the function name as PowerShell sees it.
- `ModuleVersion` — the importing module's version string. From `(Get-Module $MyModuleName).Version`.
- `SchemaRevision` — the JSON-schema version this command's output conforms to. String, semver-ish (`1.0`, `1.1`, `2.0`). Bumped when the result shape changes.
- `RunId` — a GUID generated per invocation. Lets a user correlate logs, results, and downstream artifacts that all stem from the same run.
- `TimestampUtc` — ISO 8601 UTC. Always UTC; never local time, never an offset (air-gap rule — local time leaks the host's locale).

**Encouraged fields:**

- `CommitSha` — short SHA of the running module's git commit if it can be determined cheaply. The helper `Get-<Prefix>CommitSha` should fall through gracefully to `'untracked'` when the module is installed from PSGallery or unzipped without `.git`.

**Forbidden fields** (per `air-gap-discipline`):

- `MachineName`, `Hostname`, `UserDomain`, `UserName`, IP addresses. Even `127.0.0.1` is unnecessary — the stamp already says "this run." If you need an audit trail of *which machine ran the command*, that's a logging concern (per-module transcript at `$env:USERPROFILE\Documents\<Project>\Logs\`), not a provenance-stamp concern.

## When to stamp

**Lean toward stamping** when the command:

- Returns data a user might cite, audit, or reproduce later (`Get-`, `Test-`, `Measure-`, `Find-`, `Read-` against external state).
- Returns a result that conforms to a schema downstream consumers (other modules, wikis, dashboards) read.
- Performs validation, classification, or analysis (the results inform decisions).
- Touches enterprise scope (anything in DBCCProject, ModuleWorkshop, future suite-track products).

**Skip the stamp** when the command:

- Is a one-shot helper for the caller's own session (`Set-`, `New-` for in-memory configuration).
- Returns no structured payload (e.g., `Show-` commands that print to the host).
- Is private/internal (`Private/`). Stamps are a public-surface concern.

## How to implement (per-module helper)

Each module ships a `Private/Get-<Prefix>Provenance.ps1` helper that builds the stamp. The public command calls it once per invocation and embeds the result.

```powershell
# Private/Get-SbvProvenance.ps1
function Get-SbvProvenance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $CommandName,
        [string] $SchemaRevision = '1.0'
    )

    # Module name is hardcoded by design — keep this helper PER MODULE so the
    # right module name is paired with the right prefix. Don't paste between modules.
    $mod = Get-Module SqlBackupValidation -ErrorAction SilentlyContinue
    if (-not $mod) {
        $mod = Get-Module -ListAvailable SqlBackupValidation -ErrorAction SilentlyContinue |
                   Select-Object -First 1
    }
    $version = if ($mod) { $mod.Version.ToString() } else { 'unknown' }

    [pscustomobject]@{
        Command        = $CommandName
        ModuleVersion  = $version
        SchemaRevision = $SchemaRevision
        CommitSha      = Get-SbvCommitSha
        RunId          = [guid]::NewGuid().ToString()
        TimestampUtc   = [datetime]::UtcNow.ToString('o')
    }
}
```

The companion helper that reads the running module's git commit (when available) and falls through to `'untracked'` for installed-from-PSGallery / unzipped scenarios:

```powershell
# Private/Get-SbvCommitSha.ps1
function Get-SbvCommitSha {
    [CmdletBinding()]
    param()
    try {
        $sha = git -C $PSScriptRoot rev-parse --short HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $sha) { return $sha.Trim() }
    } catch { }
    'untracked'
}
```

The public command becomes:

```powershell
$stamp = Get-SbvProvenance -CommandName $MyInvocation.MyCommand.Name
return [pscustomobject]@{
    Status     = 'Succeeded'
    # ... other fields ...
    Provenance = $stamp
}
```

## Schema impact

When `SchemaRevision` is part of the suite's JSON-schema contract (see `module-suite` skill), bumping it is a **breaking change** for downstream consumers. Changes to result shape must:

1. Bump `SchemaRevision` (semver: minor for additive, major for renamed/removed fields).
2. Update the schema doc.
3. Note the change in the module's CHANGELOG with the new revision.

Consumers that pin a schema revision (`Read-WikiData -RequireSchema '1.0'`) can keep working without surprises.

## When this skill triggers

- Authoring a new public command that returns data
- Modifying an existing public command's result shape
- Code review of any function returning a `[pscustomobject]` to a user
- Pre-release audit checking that public commands carry provenance

## What it does at trigger

1. Check whether the command qualifies for a stamp (per "When to stamp" above).
2. If yes and it's missing, propose adding the `Provenance` field.
3. Verify the stamp respects the air-gap rules (no host names, IPs, or local-time leakage).
4. For a NEW command, prompt: "What's this command's `SchemaRevision`? Does the per-module `Get-<Prefix>Provenance` helper exist?"

## What it does NOT do

- Does not require the stamp on every internal helper. Private functions don't need it.
- Does not dictate the field names beyond the required set. Project-specific extensions are fine.
- Does not replace logging. Logging records *what happened during a run*; provenance records *which version produced which answer*. Both layers are valid; keep them separate.

## The suite-wide payoff

Once every public command stamps its results, three things become true the day they ship:

1. A user pasting a result into a bug report tells you the exact module version, command, and run that produced it.
2. A wiki page generated from `Wiki_Data.json` carries the schema revision; old pages don't get silently re-rendered against incompatible new logic.
3. An auditor asking "which version produced these numbers" gets an answer without anyone having to remember.

Most PowerShell shops don't do this. That's the moat.
