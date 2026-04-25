[CmdletBinding()]
param(
    [string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2'
)
$ErrorActionPreference = 'Stop'
$test = Join-Path $ProjectRoot 'Tests\Test-GitEasyManifest.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $test -ProjectRoot $ProjectRoot
if ($LASTEXITCODE -ne 0) { throw 'GitEasy test failed.' }
