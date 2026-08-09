<#
.SYNOPSIS
Run the GitEasy Pester test suite under both PowerShell 7 and Windows PowerShell 5.1.

.DESCRIPTION
Loads Pester 5 (minimum 5.0) and runs the full Tests folder. After a passing run it
re-invokes itself under the sibling PowerShell edition (powershell.exe if running in
pwsh, or pwsh if running in powershell.exe) so that Desktop and Core compatibility are
both verified on every run.

Pester 5 must be installed in both editions. Install it once per edition with:
  Install-Module Pester -Force -SkipPublisherCheck

.PARAMETER ProjectRoot
Absolute path to the GitEasy source repository. Defaults to the repo root derived from this script's location.

.EXAMPLE
.\tools\Run-GitEasyPester.ps1

.NOTES
The module manifest declares CompatiblePSEditions = @('Desktop','Core'). Both editions
must pass before a release is cut.
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

    # Emit code-coverage data. Renders a per-file summary to stdout and writes
    # a coverage.txt artifact. Report-only — no threshold gate.
    [switch]$Coverage,

    [string]$CoverageOutputPath,

    # Suppress per-Describe/It chatter; show only totals and failure detail.
    [switch]$Quiet,

    # Internal: prevents infinite recursion when this script re-invokes itself
    # under the sibling PowerShell edition.  Not intended for direct use.
    [switch]$ThisEditionOnly
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

$pester = Get-Module -ListAvailable Pester | Where-Object { $_.Version.Major -ge 5 } | Sort-Object Version -Descending | Select-Object -First 1

if (-not $pester) {
    throw "Pester 5 is not installed. Install it with: Install-Module Pester -Force -SkipPublisherCheck"
}

Remove-Module Pester -Force -ErrorAction SilentlyContinue
Import-Module $pester.Path -Force

Write-Host ""
Write-Host "Running GitEasy Pester tests..." -ForegroundColor Cyan
Write-Host "Project: $ProjectRoot"
Write-Host "Pester:  $($pester.Version)"
Write-Host ""

# Use the PesterConfiguration object API rather than legacy Invoke-Pester
# parameters. In Pester 5+, -CodeCoverage and -Output live in different
# parameter sets, so passing both directly is AmbiguousParameterSet — the
# config object is the only unambiguous way to combine coverage with output
# control, and it works identically under Pester 5 and 6.
$config = New-PesterConfiguration
$config.Run.Path     = $testRoot
$config.Run.PassThru = $true
if ($Quiet) {
    $config.Output.Verbosity = 'Minimal'
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
        $config.CodeCoverage.Enabled = $true
        $config.CodeCoverage.Path    = $coveragePaths
    } else {
        Write-Warning "No Public/Private .ps1 files found under $ProjectRoot - coverage skipped."
        $Coverage = $false
    }
}

$result = Invoke-Pester -Configuration $config

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
    $analyzed = $cc.CommandsAnalyzedCount
    $executed = $cc.CommandsExecutedCount
    $missed   = $cc.CommandsMissedCount
    $pct      = if ($analyzed -gt 0) { [math]::Round(($executed / $analyzed) * 100, 1) } else { 0 }

    $perFile = $cc.FilesAnalyzed | ForEach-Object {
        $file       = $_
        $fileMissed = @($cc.CommandsMissed  | Where-Object { $_.File -eq $file }).Count
        $fileHit    = @($cc.CommandsExecuted | Where-Object { $_.File -eq $file }).Count
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

if (-not $ThisEditionOnly) {
    if ($PSVersionTable.PSEdition -eq 'Core') {
        $altExe  = Get-Command powershell.exe -ErrorAction SilentlyContinue
        $altName = 'Windows PowerShell 5.1'
    } else {
        $altExe  = Get-Command pwsh -ErrorAction SilentlyContinue
        $altName = 'PowerShell 7'
    }

    if ($altExe) {
        Write-Host ""
        Write-Host "==> Re-running under $altName..." -ForegroundColor Cyan
        & $altExe.Source -NonInteractive -NoProfile -File $PSCommandPath -ProjectRoot $ProjectRoot -Quiet -ThisEditionOnly
        if ($LASTEXITCODE -ne 0) {
            throw "Suite failed under $altName (exit $LASTEXITCODE). Run '$($altExe.Source) -NoProfile -File tools\Run-GitEasyPester.ps1' to see failures."
        }
        Write-Host "GitEasy Pester tests passed under $altName." -ForegroundColor Green
    } else {
        Write-Warning "$altName not found - cross-edition pass skipped."
    }
}
