# Examples-03-Check-Remote-And-Login

## Summary

Source file: `Examples\03-Check-Remote-And-Login.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\03-Check-Remote-And-Login.ps1` |
| File name | `03-Check-Remote-And-Login.ps1` |

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

Write-Host "Credential helper:" -ForegroundColor Cyan
Get-VaultStatus | Format-List

Write-Host "Remote:" -ForegroundColor Cyan
Show-Remote | Format-List

Write-Host "Login test:" -ForegroundColor Cyan
Test-Login | Format-List

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
