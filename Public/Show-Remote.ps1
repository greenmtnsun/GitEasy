function Show-Remote {
    <#
    .SYNOPSIS
    Show where the active project folder is published.

    .DESCRIPTION
    Show-Remote reports the published locations configured for the active project folder, including the kind of provider (GitHub, GitLab, or Other) and whether it is used for fetching, publishing, or both. Run it before publishing when you want to confirm the project folder is connected to the right place.

    .EXAMPLE
    Show-Remote

    .EXAMPLE
    Find-CodeChange; Show-Remote

    .NOTES
    Mismatched published locations should be treated as a stop-and-investigate signal before saving or publishing. If the listed URL is not what you expected, do not save until you understand why.

    Steps:
    1. Load the list of configured published locations.
    2. If none are found, return a single object with a "no remotes configured" message.
    3. Otherwise, return the array of published location objects.

    .LINK
    Test-Login

    .LINK
    Save-Work

    .LINK
    Find-CodeChange
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject], [System.Object[]])]
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
