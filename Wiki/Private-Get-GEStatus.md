# Private-Get-GEStatus

## Summary

Source file: `Private\Get-GEStatus.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Get-GEStatus.ps1` |
| File name | `Get-GEStatus.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-GEStatus | 1 | 8 | Path |

## Source

```powershell
function Get-GEStatus {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    $root = Get-GERepoRoot -Path $Path
    $r = Invoke-GEGit -ArgumentList @('status', '--porcelain=v1') -WorkingDirectory $root
    $lines = @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    [PSCustomObject]@{ Root = $root; Lines = $lines; IsClean = ($lines.Count -eq 0); Count = $lines.Count }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
