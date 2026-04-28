# Private-Get-GERemoteUrl

## Summary

Source file: `Private\Get-GERemoteUrl.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Get-GERemoteUrl.ps1` |
| File name | `Get-GERemoteUrl.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-GERemoteUrl | 1 | 22 | RemoteName, Path |

## Source

```powershell
function Get-GERemoteUrl {
    [CmdletBinding()]
    param(
        [string]$RemoteName = 'origin',
        [string]$Path = (Get-Location).Path
    )

    $root = Get-GERepoRoot -Path $Path
    $result = Invoke-GEGit -ArgumentList @('remote', 'get-url', $RemoteName) -WorkingDirectory $root -AllowFailure

    if ($result.ExitCode -ne 0) {
        return $null
    }

    $url = $result.Output | Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($url)) {
        return $null
    }

    return $url
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
