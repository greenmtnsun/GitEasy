# Public-Show-Remote

## Summary

Source file: `Public\Show-Remote.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Public |
| Source file | `Public\Show-Remote.ps1` |
| File name | `Show-Remote.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Show-Remote | 1 | 19 |  |

## Source

```powershell
function Show-Remote {
    [CmdletBinding()]
    param()

    $remotes = @(Get-GERemoteSummary)

    if ($remotes.Count -eq 0) {
        return [PSCustomObject]@{
            Repository = Get-GERepoRoot
            Remote     = $null
            Purpose    = $null
            Provider   = 'None'
            Url        = $null
            Message    = 'No remotes are configured.'
        }
    }

    return $remotes
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
