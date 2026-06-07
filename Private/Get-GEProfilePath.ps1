function Get-GEProfilePath {
    <#
    .SYNOPSIS
    Resolve the PowerShell startup-script path GitEasy manages for auto-loading.

    .DESCRIPTION
    Returns the current user's all-hosts profile path ($PROFILE.CurrentUserAllHosts). That file runs at the start of every PowerShell session for the current user, across the console, the ISE, and editor terminals, which makes it the right place to load GitEasy automatically. An explicit override wins for testing.

    .PARAMETER OverridePath
    Explicit path that wins over the resolved profile path. Used by tests.

    .EXAMPLE
    $profilePath = Get-GEProfilePath

    .NOTES
    Internal. No I/O; returns a path string only.

    Steps:
    1. Return the -OverridePath value if it was provided.
    2. Otherwise return the current user's all-hosts profile path.

    .LINK
    Enable-GitEasy

    .LINK
    Disable-GitEasy
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$OverridePath = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($OverridePath)) {
        return $OverridePath
    }

    return [string]$PROFILE.CurrentUserAllHosts
}
