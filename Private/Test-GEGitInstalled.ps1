function Test-GEGitInstalled {
    <#
    .SYNOPSIS
    Throw if git is not on PATH.

    .DESCRIPTION
    Sanity check that the git executable is reachable. Returns $true on success; throws otherwise.

    .EXAMPLE
    Test-GEGitInstalled | Out-Null

    .NOTES
    Internal. Read-only.

    Steps:
    1. Check whether the git executable is available on PATH.
    2. Throw a plain-English message if it is not found.
    3. Return $true.
    #>
    [CmdletBinding()]
    param()
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git was not found in PATH.'
    }
    $true
}
