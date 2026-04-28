# Public-Show-History

## Summary

Source file: `Public\Show-History.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Public |
| Source file | `Public\Show-History.ps1` |
| File name | `Show-History.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Show-History | 1 | 18 | Count |

## Source

```powershell
function Show-History {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 200)]
        [int]$Count = 20
    )

    $history = @(Get-GEHistory -Count $Count)

    if ($history.Count -eq 0) {
        return [PSCustomObject]@{
            Repository = Get-GERepoRoot
            Message    = 'No commit history found.'
        }
    }

    return $history
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
