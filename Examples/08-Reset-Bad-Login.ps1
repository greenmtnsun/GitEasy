[CmdletBinding()]
param([string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
Import-Module (Join-Path $ProjectRoot 'GitEasy.psd1') -Force

Write-Host "Current remote:" -ForegroundColor Cyan
Show-Remote | Format-List

Write-Host "Resetting cached HTTPS credential..." -ForegroundColor Cyan
Reset-Login | Format-List

Write-Host "Run Test-Login to trigger a fresh credential prompt if needed." -ForegroundColor Yellow
Test-Login | Format-List
