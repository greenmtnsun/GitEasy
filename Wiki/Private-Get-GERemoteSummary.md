# Private-Get-GERemoteSummary

## Summary

Source file: `Private\Get-GERemoteSummary.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Get-GERemoteSummary.ps1` |
| File name | `Get-GERemoteSummary.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-GERemoteSummary | 1 | 34 | Path |

## Source

```powershell
function Get-GERemoteSummary {
    [CmdletBinding()]
    param(
        [string]$Path = (Get-Location).Path
    )

    $root = Get-GERepoRoot -Path $Path
    $result = Invoke-GEGit -ArgumentList @('remote', '-v') -WorkingDirectory $root -AllowFailure

    if ($result.ExitCode -ne 0) {
        return @()
    }

    foreach ($line in @($result.Output)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line -match '^(?<Name>\S+)\s+(?<Url>\S+)\s+\((?<Purpose>fetch|push)\)$') {
            $remoteName = $Matches['Name']
            $remoteUrl = $Matches['Url']
            $purpose = $Matches['Purpose']
            $provider = Get-GEProviderName -RemoteUrl $remoteUrl

            [PSCustomObject]@{
                Repository = $root
                Remote     = $remoteName
                Purpose    = $purpose
                Provider   = $provider
                Url        = $remoteUrl
            }
        }
    }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
