# Private-Test-GERemoteUrlSafe

## Summary

Source file: `Private\Test-GERemoteUrlSafe.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Test-GERemoteUrlSafe.ps1` |
| File name | `Test-GERemoteUrlSafe.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Test-GERemoteUrlSafe | 1 | 18 | RemoteUrl |

## Source

```powershell
function Test-GERemoteUrlSafe {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$RemoteUrl)

    if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
        throw 'Remote URL is required.'
    }

    if ($RemoteUrl -match '://[^/]+@') {
        throw 'Do not embed usernames, passwords, or tokens in the remote URL. Use a clean HTTPS URL and Git Credential Manager.'
    }

    if (($RemoteUrl -notmatch '^https://') -and ($RemoteUrl -notmatch '^git@[^:]+:.+$')) {
        throw "Remote URL must be HTTPS or SSH format: $RemoteUrl"
    }

    return $true
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
