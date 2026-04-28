# Examples-07-Switch-To-Ssh

## Summary

Source file: `Examples\07-Switch-To-Ssh.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\07-Switch-To-Ssh.ps1` |
| File name | `07-Switch-To-Ssh.ps1` |

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

Write-Host "Current remote:" -ForegroundColor Cyan
Show-Remote | Format-List

Write-Host "Switching origin to SSH..." -ForegroundColor Cyan
Set-Ssh | Format-List

Write-Host "Remote after SSH change:" -ForegroundColor Cyan
Show-Remote | Format-List

Write-Host "Login test:" -ForegroundColor Cyan
Test-Login | Format-List

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
