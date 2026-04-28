# tools-Run-GitEasyTest

## Summary

Source file: `tools\Run-GitEasyTest.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Tools |
| Source file | `tools\Run-GitEasyTest.ps1` |
| File name | `Run-GitEasyTest.ps1` |

## Functions

No PowerShell functions were found in this file.

## Source

```powershell
[CmdletBinding()]
param(
    [string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2'
)
$ErrorActionPreference = 'Stop'
$test = Join-Path $ProjectRoot 'Tests\Test-GitEasyManifest.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $test -ProjectRoot $ProjectRoot
if ($LASTEXITCODE -ne 0) { throw 'GitEasy test failed.' }

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
