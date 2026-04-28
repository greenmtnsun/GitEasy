# Examples-05-Configure-GitHub-Https

## Summary

Source file: `Examples\05-Configure-GitHub-Https.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\05-Configure-GitHub-Https.ps1` |
| File name | `05-Configure-GitHub-Https.ps1` |

## Functions

No PowerShell functions were found in this file.

## Source

```powershell
[CmdletBinding()]
param(
    [string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2',
    [string]$RemoteUrl = 'https://github.com/greenmtnsun/GitEasy.git'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
Import-Module (Join-Path $ProjectRoot 'GitEasy.psd1') -Force

Write-Host "Configuring HTTPS remote:" -ForegroundColor Cyan
Write-Host $RemoteUrl

Set-Token -RemoteUrl $RemoteUrl | Format-List

Write-Host "Remote after Set-Token:" -ForegroundColor Cyan
Show-Remote | Format-List

Write-Host "Login test:" -ForegroundColor Cyan
Test-Login | Format-List

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
