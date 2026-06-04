function Format-GESafeUrl {
    <#
    .SYNOPSIS
    Return a remote URL with any embedded credentials stripped, safe for display or logging.

    .DESCRIPTION
    Some remote URLs embed credentials in the authority: scheme://user:token@host/path. That form is an anti-pattern (GitEasy's own Set-Token / Set-Ssh reject it via Test-GERemoteUrlSafe), but a repository's .git/config can already contain one — written by a clone-with-credentials, CI tooling, or a hostile repo. GitEasy must never echo such a value to the console or persist it to a diagnostic log.

    Format-GESafeUrl removes the "userinfo@" segment that sits between the scheme and the host. It will sanitise URLs that appear at the start of a string AND URLs that appear mid-string (for example, inside an error message like "fatal: cannot access 'https://x:tok@host/r'"). The scp-like SSH form (git@host:path) has no "://" and is returned unchanged, because the leading git@ there is the standard SSH user, not a secret.

    This is a display/log boundary helper. It does NOT validate the URL and is intentionally separate from Test-GERemoteUrlSafe (which rejects on the input path); this one sanitises on the read/output path.

    .PARAMETER Url
    The text to sanitise. Typically a URL, but free-form text containing one or more URLs is also supported. Null, empty, or whitespace is returned unchanged.

    .EXAMPLE
    Format-GESafeUrl -Url 'https://x-access-token:ghp_REAL@github.com/o/r.git'
    # -> 'https://github.com/o/r.git'

    .EXAMPLE
    Format-GESafeUrl -Url 'git@github.com:o/r.git'
    # -> 'git@github.com:o/r.git'   (unchanged - SSH user, not a credential)

    .EXAMPLE
    Format-GESafeUrl -Url "fatal: unable to access 'https://x:tok@host/r.git'"
    # -> "fatal: unable to access 'https://host/r.git'"   (mid-string URL sanitised)

    .NOTES
    Internal. Read-only string transform. Pairs with Test-GERemoteUrlSafe (input guard) and Get-GERemoteSummary / Reset-Login (read-path callers).

    Steps:
    1. Return the input unchanged if it is null or empty.
    2. Apply a regex that strips the "userinfo@" segment from the authority of any scheme://... URL in the text.
    3. Return the sanitized text (SSH-shaped urls like git@host:path are left unchanged).

    .LINK
    Test-GERemoteUrlSafe

    .LINK
    Show-Remote

    .LINK
    Reset-Login
    #>
    [CmdletBinding()]
    param(
        [string]$Url
    )

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return $Url
    }

    # Strip a "userinfo@" that appears in the authority of a scheme://... URL.
    # [^/@]+ stops at the first '/' or '@', so a literal '@' that occurs later
    # in the path (https://host/a@b) is left alone, and the scp-like SSH form
    # (git@host:path, no '://') never matches. The regex is NOT anchored so it
    # also catches URLs embedded mid-string in free-form text (e.g. git error
    # messages that quote the offending URL).
    return [System.Text.RegularExpressions.Regex]::Replace(
        $Url,
        '(?<scheme>[a-zA-Z][a-zA-Z0-9+.\-]*://)[^/@]+@',
        '${scheme}'
    )
}
