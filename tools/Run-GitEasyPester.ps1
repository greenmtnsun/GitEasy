<#
.SYNOPSIS
Run the GitEasy Pester test suite using Pester 3 (the version the tests were written for).

.DESCRIPTION
Explicitly loads Pester 3 (preferring 3.4.x) and invokes the test runner over the Tests folder. GitEasy tests are written in Pester 3 syntax; loading Pester 5 would silently mis-run them via the legacy adapter, so this script pins Pester 3 to keep behavior deterministic across machines.

.PARAMETER ProjectRoot
Absolute path to the GitEasy source repository. Defaults to C:\Sysadmin\Scripts\GitEasy.

.EXAMPLE
.\tools\Run-GitEasyPester.ps1

.NOTES
Most environments ship Pester 3 by default with Windows PowerShell 5.1. Tests must work against Pester 3.
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasy',

    # Emit Pester 3 code-coverage data. Pester 3 has no native
    # JaCoCo / Cobertura export, so we render a per-file summary
    # to stdout and write a coverage.txt artifact for the CI to
    # publish. Report-only - no threshold gate.
    [switch]$Coverage,

    [string]$CoverageOutputPath,

    # Suppress Pester 3's per-Describe/It chatter; show only the
    # totals summary and any failure detail. Matches the prior
    # CI contract that called Invoke-Pester -Quiet directly.
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    throw "Missing project folder: $ProjectRoot"
}

$testRoot = Join-Path $ProjectRoot 'Tests'

if (-not (Test-Path -LiteralPath $testRoot)) {
    throw "Missing test folder: $testRoot"
}

$pester = Get-Module -ListAvailable Pester | Where-Object { $_.Version.Major -lt 4 } | Sort-Object Version -Descending | Select-Object -First 1

if (-not $pester) {
    throw "Pester 3 is not installed. Install it with: Install-Module Pester -RequiredVersion 3.4.0 -SkipPublisherCheck -Scope AllUsers -Force"
}

Remove-Module Pester -Force -ErrorAction SilentlyContinue
Import-Module $pester.Path -Force

Write-Host ""
Write-Host "Running GitEasy Pester tests..." -ForegroundColor Cyan
Write-Host "Project: $ProjectRoot"
Write-Host "Pester:  $($pester.Version)"
Write-Host ""

$invokeParams = @{
    Script   = $testRoot
    PassThru = $true
}
if ($Quiet) {
    $invokeParams.Quiet = $true
}

if ($Coverage) {
    $publicRoot  = Join-Path $ProjectRoot 'Public'
    $privateRoot = Join-Path $ProjectRoot 'Private'
    $coveragePaths = @()
    foreach ($r in @($publicRoot, $privateRoot)) {
        if (Test-Path -LiteralPath $r) {
            $coveragePaths += (Get-ChildItem -Path $r -Filter '*.ps1' -Recurse -File).FullName
        }
    }
    if ($coveragePaths.Count -gt 0) {
        $invokeParams.CodeCoverage = $coveragePaths
    } else {
        Write-Warning "No Public/Private .ps1 files found under $ProjectRoot - coverage skipped."
        $Coverage = $false
    }
}

$result = Invoke-Pester @invokeParams

$summary = [PSCustomObject]@{
    Total   = $result.TotalCount
    Passed  = $result.PassedCount
    Failed  = $result.FailedCount
    Skipped = $result.SkippedCount
}

Write-Host ""
Write-Host "GitEasy Pester summary:" -ForegroundColor Cyan
$summary | Format-List

if ($Coverage -and $result.PSObject.Properties['CodeCoverage'] -and $result.CodeCoverage) {
    $cc = $result.CodeCoverage
    $analyzed = $cc.NumberOfCommandsAnalyzed
    $executed = $cc.NumberOfCommandsExecuted
    $missed   = $cc.NumberOfCommandsMissed
    $pct      = if ($analyzed -gt 0) { [math]::Round(($executed / $analyzed) * 100, 1) } else { 0 }

    $perFile = $cc.AnalyzedFiles | ForEach-Object {
        $file       = $_
        $fileMissed = @($cc.MissedCommands | Where-Object { $_.File -eq $file }).Count
        $fileHit    = @($cc.HitCommands    | Where-Object { $_.File -eq $file }).Count
        $fileTotal  = $fileHit + $fileMissed
        $filePct    = if ($fileTotal -gt 0) { [math]::Round(($fileHit / $fileTotal) * 100, 1) } else { 0 }
        [PSCustomObject]@{
            File     = (Split-Path -Leaf $file)
            Hit      = $fileHit
            Missed   = $fileMissed
            Total    = $fileTotal
            Percent  = $filePct
        }
    } | Sort-Object Percent

    Write-Host ""
    Write-Host "Code coverage: $executed / $analyzed commands ($pct%)" -ForegroundColor Cyan
    $perFile | Format-Table -AutoSize | Out-String | Write-Host

    if (-not $CoverageOutputPath) {
        $CoverageOutputPath = Join-Path $ProjectRoot 'coverage.txt'
    }
    $reportLines = @(
        "GitEasy code coverage",
        "Generated: $(Get-Date -Format 'o')",
        "Total: $executed / $analyzed commands ($pct%)",
        "Missed: $missed",
        "",
        "Per-file:"
    )
    $reportLines += ($perFile | Format-Table -AutoSize | Out-String).TrimEnd()
    Set-Content -Path $CoverageOutputPath -Value $reportLines -Encoding UTF8
    Write-Host "Coverage report written to $CoverageOutputPath" -ForegroundColor Cyan
}

if ($result.FailedCount -gt 0) {
    throw "GitEasy Pester tests failed."
}

Write-Host "GitEasy Pester tests passed." -ForegroundColor Green
