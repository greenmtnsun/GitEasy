# =============================================================================
# Script  : Test-GitEasyProjectState.ps1
# Author  : Keith Ramsey
# Created : 2026-05-27
# =============================================================================
# Change Log
# -----------------------------------------------------------------------------
# 2026-05-27  cross-suite meta Claude  Initial: project-state checker per the
#                            suite convention (Tools/Test-*ProjectState.ps1).
#                            Lean shape — required folders, manifest sanity,
#                            manifest-export <-> Public/ parity. Pairs with
#                            Run-GitEasyPester.ps1 (existing) and the existing
#                            audit tools in Tools/ (Audit-PublicJargon,
#                            Audit-GEUsage), which cover deeper concerns.
# =============================================================================

[CmdletBinding()]
param(
    [string] $ProjectRoot,
    [switch] $CiMode
)

if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    <#
    .DESCRIPTION
    Internal. Appends a check result record to the script-scoped results list.
    Steps:
    1. Build a result object with check name, status, outcome, error category, and path.
    2. Add the object to the results list.
    #>
    param(
        [string] $Check,
        [string] $Status,
        [string] $Outcome,
        [string] $ErrorCategory = 'None',
        [string] $Path = ''
    )
    $results.Add([pscustomobject]@{
        Check         = $Check
        Status        = $Status
        Outcome       = $Outcome
        ErrorCategory = $ErrorCategory
        Path          = $Path
    })
}

# --- Required folders --------------------------------------------------------
$required = 'Public', 'Private', 'Tests', 'Tests\Unit', 'docs', 'Tools', 'Wiki'
foreach ($r in $required) {
    $p = Join-Path $ProjectRoot $r
    if (Test-Path -LiteralPath $p -PathType Container) {
        Add-Result -Check 'RequiredFolder' -Status 'Succeeded' -Outcome "Folder present: $r" -Path $p
    } else {
        Add-Result -Check 'RequiredFolder' -Status 'HandledError' -Outcome "Missing folder: $r" -ErrorCategory 'MissingFolder' -Path $p
    }
}

# --- Manifest + loader exist -------------------------------------------------
$psd1 = Join-Path $ProjectRoot 'GitEasy.psd1'
$psm1 = Join-Path $ProjectRoot 'GitEasy.psm1'
foreach ($f in @($psd1, $psm1)) {
    if (Test-Path -LiteralPath $f) {
        Add-Result -Check 'ManifestPresent' -Status 'Succeeded' -Outcome "Present: $(Split-Path $f -Leaf)" -Path $f
    } else {
        Add-Result -Check 'ManifestPresent' -Status 'HandledError' -Outcome "Missing: $(Split-Path $f -Leaf)" -ErrorCategory 'MissingFile' -Path $f
    }
}

# --- FunctionsToExport matches Public/ ---------------------------------------
if (Test-Path -LiteralPath $psd1) {
    try {
        $manifest = Import-PowerShellDataFile -Path $psd1
        $declared = @($manifest.FunctionsToExport)
        $publicDir = Join-Path $ProjectRoot 'Public'
        $publicFiles = if (Test-Path -LiteralPath $publicDir) {
            @(Get-ChildItem -LiteralPath $publicDir -Filter *.ps1 -File | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) })
        } else { @() }

        $missing = $publicFiles | Where-Object { $declared -notcontains $_ }
        $extra   = $declared    | Where-Object { $publicFiles -notcontains $_ }

        if ($missing.Count -eq 0 -and $extra.Count -eq 0) {
            Add-Result -Check 'ManifestExports' -Status 'Succeeded' -Outcome "Manifest exports match $($publicFiles.Count) Public/ files."
        } else {
            $msg = ''
            if ($missing.Count) { $msg += "Missing from manifest: $($missing -join ',') " }
            if ($extra.Count)   { $msg += "Declared but no file: $($extra -join ',')" }
            Add-Result -Check 'ManifestExports' -Status 'HandledError' -Outcome $msg -ErrorCategory 'ManifestMismatch' -Path $psd1
        }
    } catch {
        Add-Result -Check 'ManifestExports' -Status 'HandledError' -Outcome "Manifest load failed: $($_.Exception.Message)" -ErrorCategory 'ManifestLoadFailed' -Path $psd1
    }
}

# --- Suite-convention docs (these are the audit gaps still open) -------------
$conventionDocs = @{
    'docs\PHASE.txt'             = 'PhaseDocs'
    'docs\DECISION_REGISTER.md'  = 'PhaseDocs'
    'PSScriptAnalyzerSettings.psd1' = 'PSSAConfig'
}
foreach ($k in $conventionDocs.Keys) {
    $f = Join-Path $ProjectRoot $k
    if (Test-Path -LiteralPath $f) {
        Add-Result -Check $conventionDocs[$k] -Status 'Succeeded' -Outcome "Present: $k" -Path $f
    } else {
        Add-Result -Check $conventionDocs[$k] -Status 'HandledError' -Outcome "Missing: $k" -ErrorCategory 'MissingFile' -Path $f
    }
}

# --- Summary -----------------------------------------------------------------
$failed = @($results | Where-Object Status -eq 'HandledError')
$summary = [pscustomobject]@{
    PSTypeName    = 'GitEasy.ProjectState'
    Status        = if ($failed.Count -eq 0) { 'Succeeded' } else { 'HandledError' }
    Outcome       = "$($results.Count) checks; $($failed.Count) failures."
    ErrorCategory = if ($failed.Count -eq 0) { 'None' } else { 'StateCheckFailed' }
    Results       = $results.ToArray()
    FailureCount  = $failed.Count
    TotalCount    = $results.Count
}

if ($CiMode) {
    if ($failed.Count -eq 0) { exit 0 } else { exit 1 }
}

$summary
