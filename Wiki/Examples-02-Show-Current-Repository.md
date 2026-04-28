# Examples-02-Show-Current-Repository

## Summary

Source file: `Examples\02-Show-Current-Repository.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\02-Show-Current-Repository.ps1` |
| File name | `02-Show-Current-Repository.ps1` |

## Functions

No PowerShell functions were found in this file.

## Source

```powershell
[CmdletBinding()]
param([string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
Import-Module (Join-Path $ProjectRoot 'GitEasy.psd1') -Force

Write-Host "Repository status:" -ForegroundColor Cyan
Find-CodeChange | Format-List

Write-Host ""
Write-Host "History:" -ForegroundColor Cyan
Show-History -Count 5 | Format-Table -AutoSize

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
