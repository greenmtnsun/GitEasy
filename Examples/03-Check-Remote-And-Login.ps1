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
