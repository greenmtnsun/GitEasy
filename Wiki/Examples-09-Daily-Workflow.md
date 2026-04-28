# Examples-09-Daily-Workflow

## Summary

Source file: `Examples\09-Daily-Workflow.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\09-Daily-Workflow.ps1` |
| File name | `09-Daily-Workflow.ps1` |

## Functions

No PowerShell functions were found in this file.

## Source

```powershell
[CmdletBinding()]
param(
    [string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2',
    [string]$Message = 'daily checkpoint'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
Import-Module (Join-Path $ProjectRoot 'GitEasy.psd1') -Force

Write-Host "1. Current changes" -ForegroundColor Cyan
Find-CodeChange | Format-List

Write-Host "2. Current remote" -ForegroundColor Cyan
Show-Remote | Format-List

Write-Host "3. Login test" -ForegroundColor Cyan
Test-Login | Format-List

Write-Host "4. Save local checkpoint" -ForegroundColor Cyan
Save-Work $Message -NoPush

Write-Host "5. Recent history" -ForegroundColor Cyan
Show-History -Count 5 | Format-Table -AutoSize

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
