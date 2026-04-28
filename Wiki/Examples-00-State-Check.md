# Examples-00-State-Check

## Summary

Source file: `Examples\00-State-Check.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\00-State-Check.ps1` |
| File name | `00-State-Check.ps1` |

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

Write-Host ""
Write-Host "GitEasy V2 State Check" -ForegroundColor Cyan
Write-Host "ProjectRoot: $ProjectRoot"

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    throw "Project folder not found: $ProjectRoot"
}

$modulePath = Join-Path $ProjectRoot 'GitEasy.psd1'

if (-not (Test-Path -LiteralPath $modulePath)) {
    throw "Module manifest not found: $modulePath"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git was not found in PATH."
}

Set-Location -LiteralPath $ProjectRoot
Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

Write-Host ""
Write-Host "Module commands:" -ForegroundColor Cyan
Get-Command -Module GitEasy | Select-Object CommandType, Name, Version, Source | Format-Table -AutoSize

Write-Host ""
Write-Host "Git status:" -ForegroundColor Cyan
git status --short

Write-Host ""
Write-Host "Git branch:" -ForegroundColor Cyan
git branch --show-current

Write-Host ""
Write-Host "Remote:" -ForegroundColor Cyan
Show-Remote | Format-List

Write-Host ""
Write-Host "Login test:" -ForegroundColor Cyan
Test-Login | Format-List

Write-Host ""
Write-Host "Change summary:" -ForegroundColor Cyan
Find-CodeChange | Format-List

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
