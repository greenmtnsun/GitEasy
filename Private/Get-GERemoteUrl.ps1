function Get-GERemoteUrl {
    <#
    .SYNOPSIS
    Return the URL of a published location, or $null if it is not configured.

    .DESCRIPTION
    Wraps git remote get-url. Returns $null on missing remote rather than throwing so callers can branch cleanly.

    .PARAMETER RemoteName
    The published location to query. Defaults to origin.

    .PARAMETER Path
    The folder to query. Defaults to the current location.

    .EXAMPLE
    $url = Get-GERemoteUrl -RemoteName origin

    .NOTES
    Internal. Read-only.

    Steps:
    1. Find the project folder root.
    2. Query the URL of the named published location; return $null on failure.
    3. Return $null if the result is empty; otherwise return the URL string.

    .LINK
    Show-Remote
    #>
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
