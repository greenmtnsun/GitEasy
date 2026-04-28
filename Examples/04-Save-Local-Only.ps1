[CmdletBinding()]
param(
    [string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2',
    [string]$Message = 'local checkpoint from GitEasy example'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
Import-Module (Join-Path $ProjectRoot 'GitEasy.psd1') -Force

Write-Host "Before save:" -ForegroundColor Cyan
Find-CodeChange | Format-List

Write-Host "Saving local checkpoint only..." -ForegroundColor Cyan
Save-Work $Message -NoPush

Write-Host "After save:" -ForegroundColor Cyan
Find-CodeChange | Format-List
