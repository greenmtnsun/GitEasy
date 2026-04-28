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
