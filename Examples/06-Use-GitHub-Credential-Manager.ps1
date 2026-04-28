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
