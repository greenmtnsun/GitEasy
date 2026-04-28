# GitEasy

## Summary

Source file: `GitEasy.psm1`

## Classification

| Field | Value |
| --- | --- |
| Area | Root |
| Source file | `GitEasy.psm1` |
| File name | `GitEasy.psm1` |

## Functions

No PowerShell functions were found in this file.

## Source

```powershell
Set-StrictMode -Version Latest
$privatePath = Join-Path $PSScriptRoot 'Private'
$publicPath = Join-Path $PSScriptRoot 'Public'
Get-ChildItem -LiteralPath $privatePath -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object { . $_.FullName }
Get-ChildItem -LiteralPath $publicPath -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object { . $_.FullName }
Export-ModuleMember -Function @(
    'Clear-Junk',
    'Find-CodeChange',
    'Get-VaultStatus',
    'New-WorkBranch',
    'Reset-Login',
    'Restore-File',
    'Save-Work',
    'Set-Ssh',
    'Set-Token',
    'Set-Vault',
    'Show-History',
    'Show-Remote',
    'Switch-Work',
    'Test-Login',
    'Undo-Changes'
)

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
