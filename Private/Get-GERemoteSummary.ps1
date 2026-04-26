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
