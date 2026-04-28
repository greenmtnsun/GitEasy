# Examples-01-Import-And-List-Commands

## Summary

Source file: `Examples\01-Import-And-List-Commands.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\01-Import-And-List-Commands.ps1` |
| File name | `01-Import-And-List-Commands.ps1` |

## Functions

No PowerShell functions were found in this file.

## Source

```powershell
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

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
