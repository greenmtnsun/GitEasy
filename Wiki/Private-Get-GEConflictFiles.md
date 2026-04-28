# Private-Get-GEConflictFiles

## Summary

Source file: `Private\Get-GEConflictFiles.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Get-GEConflictFiles.ps1` |
| File name | `Get-GEConflictFiles.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-GEConflictFiles | 1 | 7 | Path |

## Source

```powershell
function Get-GEConflictFiles {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    $root = Get-GERepoRoot -Path $Path
    $r = Invoke-GEGit -ArgumentList @('diff', '--name-only', '--diff-filter=U') -WorkingDirectory $root -AllowFailure
    @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
