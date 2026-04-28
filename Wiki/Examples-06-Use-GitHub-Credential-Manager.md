# Examples-06-Use-GitHub-Credential-Manager

## Summary

Source file: `Examples\06-Use-GitHub-Credential-Manager.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\06-Use-GitHub-Credential-Manager.ps1` |
| File name | `06-Use-GitHub-Credential-Manager.ps1` |

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

Write-Host "Before:" -ForegroundColor Cyan
Get-VaultStatus | Format-List

Write-Host "Setting credential helper to manager..." -ForegroundColor Cyan
Set-Vault -Helper manager | Format-List

Write-Host "After:" -ForegroundColor Cyan
Get-VaultStatus | Format-List

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
