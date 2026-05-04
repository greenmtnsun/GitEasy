[CmdletBinding()]
param([string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasy')

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
