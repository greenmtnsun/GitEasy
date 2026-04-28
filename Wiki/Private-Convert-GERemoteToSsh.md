# Private-Convert-GERemoteToSsh

## Summary

Source file: `Private\Convert-GERemoteToSsh.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Convert-GERemoteToSsh.ps1` |
| File name | `Convert-GERemoteToSsh.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Convert-GERemoteToSsh | 1 | 14 | RemoteUrl |

## Source

```powershell
function Convert-GERemoteToSsh {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$RemoteUrl)

    if ($RemoteUrl -match '^git@[^:]+:.+$') {
        return $RemoteUrl
    }

    if ($RemoteUrl -notmatch '^https://(?<Host>[^/]+)/(?<Path>.+)$') {
        throw "Remote URL is not a recognized HTTPS Git URL: $RemoteUrl"
    }

    return "git@$($Matches.Host):$($Matches.Path)"
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
