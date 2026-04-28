[CmdletBinding()]
param([string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $ProjectRoot 'GitEasy.psd1') -Force

Get-Command -Module GitEasy |
    Sort-Object Name |
    Select-Object CommandType, Name, Version, Source |
    Format-Table -AutoSize
