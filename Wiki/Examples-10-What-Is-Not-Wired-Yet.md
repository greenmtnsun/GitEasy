# Examples-10-What-Is-Not-Wired-Yet

## Summary

Source file: `Examples\10-What-Is-Not-Wired-Yet.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `Examples\10-What-Is-Not-Wired-Yet.ps1` |
| File name | `10-What-Is-Not-Wired-Yet.ps1` |

## Functions

No PowerShell functions were found in this file.

## Source

```powershell
[CmdletBinding()]
param([string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasyV2')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
Import-Module (Join-Path $ProjectRoot 'GitEasy.psd1') -Force

$commands = @(
    'New-WorkBranch',
    'Switch-Work',
    'Undo-Changes',
    'Restore-File',
    'Clear-Junk'
)

foreach ($command in $commands) {
    $path = Join-Path $ProjectRoot "Public\$command.ps1"
    $content = Get-Content -LiteralPath $path -Raw

    [PSCustomObject]@{
        Command = $command
        Wired   = ($content -notmatch 'not wired yet')
        File    = $path
    }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
