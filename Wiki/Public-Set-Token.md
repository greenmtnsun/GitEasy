# Public-Set-Token

## Summary

Source file: `Public\Set-Token.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Public |
| Source file | `Public\Set-Token.ps1` |
| File name | `Set-Token.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Set-Token | 1 | 35 | RemoteUrl, RemoteName |

## Source

```powershell
function Set-Token {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$RemoteUrl,
        [string]$RemoteName = 'origin'
    )

    Test-GERemoteUrlSafe -RemoteUrl $RemoteUrl | Out-Null

    if ($RemoteUrl -notmatch '^https://') {
        throw 'Set-Token only accepts clean HTTPS remote URLs.'
    }

    $root = Get-GERepoRoot

    if (-not $PSCmdlet.ShouldProcess($root, "Set $RemoteName to HTTPS remote URL")) {
        return
    }

    $existing = Get-GERemoteUrl -RemoteName $RemoteName -Path $root

    if ([string]::IsNullOrWhiteSpace($existing)) {
        Invoke-GEGit -ArgumentList @('remote', 'add', $RemoteName, $RemoteUrl) -WorkingDirectory $root | Out-Null
    }
    else {
        Invoke-GEGit -ArgumentList @('remote', 'set-url', $RemoteName, $RemoteUrl) -WorkingDirectory $root | Out-Null
    }

    [PSCustomObject]@{
        Repository = $root
        Remote     = $RemoteName
        Url        = $RemoteUrl
        Message    = 'HTTPS remote configured. Run Test-Login to validate credentials.'
    }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
