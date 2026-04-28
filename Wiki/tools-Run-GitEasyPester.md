# tools-Run-GitEasyPester

## Summary

Source file: `tools\Run-GitEasyPester.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Tools |
| Source file | `tools\Run-GitEasyPester.ps1` |
| File name | `Run-GitEasyPester.ps1` |

## Functions

No PowerShell functions were found in this file.

## Source

```powershell
[CmdletBinding()]
param(
    [string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2'
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

$pester = Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1

if (-not $pester) {
    throw "Pester is not installed. Install it with: Install-Module Pester -Scope CurrentUser -Force"
}

Import-Module $pester.Path -Force

Write-Host ""
Write-Host "Running GitEasy Pester tests..." -ForegroundColor Cyan
Write-Host "Project: $ProjectRoot"
Write-Host "Pester:  $($pester.Version)"
Write-Host ""

if ($pester.Version.Major -ge 5) {
    $result = Invoke-Pester -Path $testRoot -PassThru -Output Detailed
}
else {
    $result = Invoke-Pester -Script $testRoot -PassThru
}

$summary = [PSCustomObject]@{
    Total   = $result.TotalCount
    Passed  = $result.PassedCount
    Failed  = $result.FailedCount
    Skipped = $result.SkippedCount
}

Write-Host ""
Write-Host "GitEasy Pester summary:" -ForegroundColor Cyan
$summary | Format-List

if ($result.FailedCount -gt 0) {
    throw "GitEasy Pester tests failed."
}

Write-Host "GitEasy Pester tests passed." -ForegroundColor Green

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
