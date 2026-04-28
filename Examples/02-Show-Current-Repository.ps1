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
