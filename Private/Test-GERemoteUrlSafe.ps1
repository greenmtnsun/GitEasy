function Test-GERemoteUrlSafe {
    <#
    .SYNOPSIS
    Throw if a remote URL embeds credentials or is not HTTPS or SSH.

    .DESCRIPTION
    Rejects URLs of the form scheme://user@host/path (where credentials are pasted into the URL itself) and rejects any URL that is not HTTPS or SSH. Returns $true on success.

    .PARAMETER RemoteUrl
    The URL to validate.

    .EXAMPLE
    Test-GERemoteUrlSafe -RemoteUrl 'https://github.com/example/repo.git'

    .NOTES
    Internal. Read-only validation.

    Steps:
    1. Throw if the URL is empty or null.
    2. Throw if the URL embeds credentials in the authority (the ://user@host pattern).
    3. Throw if the URL is neither HTTPS nor SSH format.
    4. Return $true.

    .LINK
    Set-Token

    .LINK
    Set-Ssh
    #>
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
