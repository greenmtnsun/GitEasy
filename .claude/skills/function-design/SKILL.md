---
name: function-design
description: Use when authoring or modifying a public function in any of Keith's suite projects. Codifies the parameter / pipeline / output contract — pipeline-friendly, ParameterSet conventions, ShouldProcess for state-changing commands, structured-result return on every path, plain-English public surface, comment-based help minimums, approved verbs only. Pairs with the phantom-verb-killer hook.
---

> See also: `software-creation` §1, §4, §5 for the broader discipline. `module-suite` for cross-product strategy. `air-gap-discipline` for environment rules. `editorial-stance` for documentation-output rules.

# Function design — the public-surface contract

The shape of a public function is the suite's user experience. A user who runs `Get-MWLayout` should be able to predict the shape of `Test-MWProject` without reading docs. That predictability comes from a few contract rules. Lean hard on them; deviate only when there's a real reason. Two of the seven (§5 plain-English, §7 approved verbs) are hard lines — the rest are strong defaults.

## 1. Pipeline-friendly by default

Lean toward accepting input via the pipeline on every public command that takes data.

```powershell
function Get-MWLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $ProjectRoot
    )
    process {
        # one input at a time
    }
}
```

When a function operates on a list, accept the list element-by-element via the pipeline AND as a list parameter. Don't force the caller to choose between two invocation shapes.

## 2. ParameterSet for mutually exclusive inputs

When a command can take input two ways (path vs object, name vs id), default to named parameter sets:

```powershell
[CmdletBinding(DefaultParameterSetName = 'ByPath')]
param(
    [Parameter(Mandatory, ParameterSetName = 'ByPath')]
    [string] $Path,

    [Parameter(Mandatory, ParameterSetName = 'ByObject', ValueFromPipeline)]
    [pscustomobject] $InputObject
)
```

Don't accept both at once. PowerShell's parameter binding does the disambiguation; the function body doesn't need to.

## 3. ShouldProcess for state-changing commands

Default any command that *changes state* — writes a file, modifies a database, calls an external API with side effects — to support `-WhatIf` and `-Confirm`:

```powershell
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(...)
process {
    if ($PSCmdlet.ShouldProcess($Target, 'Update manifest')) {
        # do the change
    }
}
```

`Get-`, `Test-`, `Find-`, `Read-` commands don't need it. Anything that mutates does.

## 4. Structured result on every return path

Per `software-creation` §4: never throw on operational failures. Return a `[pscustomobject]` with at minimum `Status`, `Outcome`, `ErrorCategory`. Every code path returns a result — including the catch block.

Don't mix patterns. A function that returns `[string]` on one path and a structured object on another is broken.

```powershell
try {
    # ...
    return [pscustomobject]@{
        Status        = 'Succeeded'
        Outcome       = "Created package at $OutputPath"
        ErrorCategory = 'None'
        OutputPath    = $OutputPath
    }
} catch {
    return [pscustomobject]@{
        Status        = 'HandledError'
        Outcome       = "Failed to package: $($_.Exception.Message)"
        ErrorCategory = 'HandledError'
    }
}
```

## 5. Plain-English public surface

Per `software-creation` §5 and `feedback_giteasy_no_jargon.md`. Function names, parameter names, and error messages stay in plain English. Engine internals can carry complexity; the public surface stays readable to a sysadmin who has never seen the code.

Examples of *wrong*: `Invoke-PfPx -Mode 'CI' -Tgt 'X'`, `ErrorCategory = 'CSE'`.
Examples of *right*: `Invoke-PesterForge -ScriptPath '...' -CiMode`, `ErrorCategory = 'ConnectionFailed'`.

## 6. Comment-based help minimums

Every public function carries at least:

- `.SYNOPSIS` — one-line description
- `.DESCRIPTION` — paragraph: what it does and when to use it
- `.EXAMPLE` — at least one realistic, runnable example (per `feedback_examples_quality.md`)

`.PARAMETER` blocks for non-obvious parameters. `.NOTES` for cross-references, version history, contributor credit. Examples must be real — placeholder examples are worse than no example.

## 7. Approved verbs only

Per ModuleWorkshop DR-005. Public-surface commands use verbs from PowerShell's approved-verb list. Run `Get-Verb` to see it. The `phantom-verb-killer` hook (PreToolUse on Edit/Write to `Public/` files) blocks saves that introduce a function with an unapproved verb.

## When this skill triggers

- Authoring a new public function in any suite project
- Modifying an existing public function's parameters, return shape, or error handling
- Code review of a public-surface change
- Pre-release audit checking surface consistency

## What it does at trigger

1. Check the function against the seven rules. Flag deviations.
2. Suggest the canonical shape if a contract rule is missed.
3. For a NEW public function, prompt: "Approved verb? Right parameter set shape? Need ShouldProcess? Structured return on every path? CBH minimums met?"

## What it does NOT do

- Does not apply to private/internal helpers in `Private/`. Those have a different bar (atomicity, structured results, but pipeline-friendliness is optional).
- Does not dictate parameter *names* — that's project-by-project (each module's prefix and noun choices are local).

## Hooks backing this skill

- `phantom-verb-killer` blocks saves with unapproved verbs in `Public/` files.
