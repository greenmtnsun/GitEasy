function Convert-GERemoteToSsh {
    <#
    .SYNOPSIS
    Convert an HTTPS Git URL to its SSH form.

    .DESCRIPTION
    Translates https://host/path to git@host:path. Returns SSH URLs unchanged. Throws when the input is not a recognized HTTPS URL, and throws when the input embeds credentials in the authority (scheme://user:token@host) — converting such a URL would persist the secret into the SSH form and the diagnostic log.

    .PARAMETER RemoteUrl
    The URL to convert.

    .EXAMPLE
    Convert-GERemoteToSsh -RemoteUrl 'https://github.com/example/repo.git'

    .NOTES
    Internal. Pure transformation. No I/O. Uses [uri] for parsing so that an embedded user:token@ cannot be mistaken for the host (the F-04 fix; sibling of the F-02 Reset-Login parse fix).

    Steps:
    1. Return the URL unchanged if it is already SSH-shaped.
    2. Parse the URL; throw if it is not a recognized HTTPS URL.
    3. Throw if the URL embeds credentials in the authority segment.
    4. Build and return the SSH form: git@host:path.

    .LINK
    Set-Ssh
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$RemoteUrl)

    if ($RemoteUrl -match '^git@[^:]+:.+$') {
        return $RemoteUrl
    }

    $parsed = $RemoteUrl -as [uri]

    if ((-not $parsed) -or ($parsed.Scheme -ne 'https') -or [string]::IsNullOrWhiteSpace($parsed.Host)) {
        throw "Remote URL is not a recognized HTTPS Git URL: $(Format-GESafeUrl -Url $RemoteUrl)"
    }

    if (-not [string]::IsNullOrWhiteSpace($parsed.UserInfo)) {
        # Refuse to convert a URL with embedded credentials. The userinfo
        # segment is the F-02/F-04 leak vector — converting it would write
        # the secret into `git remote set-url` and the diagnostic log.
        throw 'Do not embed usernames, passwords, or tokens in the remote URL. Use a clean HTTPS URL and Git Credential Manager.'
    }

    $path = $parsed.AbsolutePath.TrimStart('/')

    return "git@$($parsed.Host):$path"
}
