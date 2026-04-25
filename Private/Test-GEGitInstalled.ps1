function Test-GEGitInstalled {
    [CmdletBinding()]
    param()
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git was not found in PATH.'
    }
    $true
}
