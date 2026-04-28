# Private-Get-GEProviderName

## Summary

Source file: `Private\Get-GEProviderName.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Get-GEProviderName.ps1` |
| File name | `Get-GEProviderName.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-GEProviderName | 1 | 18 | RemoteUrl |

## Source

```powershell
function Get-GEProviderName {
    [CmdletBinding()]
    param([string]$RemoteUrl)

    if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
        return 'None'
    }

    if ($RemoteUrl -match 'github\.com[:/]') {
        return 'GitHub'
    }

    if ($RemoteUrl -match 'gitlab\.com[:/]') {
        return 'GitLab'
    }

    return 'Unknown'
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
