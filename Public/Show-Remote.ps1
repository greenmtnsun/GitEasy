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
