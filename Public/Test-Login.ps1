function Test-Login {
    <#
    .SYNOPSIS
    Verify that GitEasy can talk to the published location.

    .DESCRIPTION
    Test-Login checks whether the current login can read the published location for the active project folder. It reports the project, the active working area, the published location, the provider (GitHub, GitLab, or Other), and whether the connectivity test passed.

    Run Test-Login before publishing for the first time, after Set-Token or Set-Ssh, or any time Save-Work cannot publish.

    .PARAMETER RemoteName
    The name of the published location to test. Defaults to origin.

    .EXAMPLE
    Test-Login

    .EXAMPLE
    Show-Remote; Test-Login

    .NOTES
    A failed Test-Login should be fixed before running Save-Work. The returned object includes the technical exit code for follow-up.

    Steps:
    1. Find the project folder root, the active working area, and the URL of the published location.
    2. Sanitize the URL before exposing it on the returned object (strips any embedded credentials).
    3. If no published location is configured, return a failed result immediately.
    4. Run a read-only connectivity check against the published location.
    5. Sanitize any error output from the check before it reaches the returned object.
    6. Return a structured result with the project, working area, provider, URL, pass/fail status, and exit code.

    .LINK
    Set-Token

    .LINK
    Set-Ssh

    .LINK
    Reset-Login

    .LINK
    Show-Remote
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$RemoteName = 'origin'
    )

    $root = Get-GERepoRoot
    $branch = Get-GEBranchName -Path $root
    $remoteUrl = Get-GERemoteUrl -RemoteName $RemoteName -Path $root
    $provider = Get-GEProviderName -RemoteUrl $remoteUrl

    # F-05: .git/config is an untrusted read-path input; the URL may carry
    # embedded credentials. Sanitise before exposing on the returned object
    # or echoing through Get-GEProviderName-derived display.
    $safeUrl = Format-GESafeUrl -Url $remoteUrl

    if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        return [PSCustomObject]@{
            Repository = $root
            Branch     = $branch
            Remote     = $RemoteName
            Provider   = $provider
            Url        = $null
            Passed     = $false
            ExitCode   = $null
            Message    = "Remote '$RemoteName' is not configured."
        }
    }

    $result = Invoke-GEGit -ArgumentList @('ls-remote', '--heads', $RemoteName) -WorkingDirectory $root -AllowFailure

    if ($result.ExitCode -eq 0) {
        $message = 'Remote login/connectivity test passed.'
    }
    else {
        # F-05: ls-remote stderr can quote the offending URL in an error
        # message ("fatal: unable to access 'https://x:tok@host/...'").
        # Sanitise each line so any embedded credential is stripped before
        # it lands on the returned object.
        $message = ($result.Output | ForEach-Object { Format-GESafeUrl -Url $_ }) -join [Environment]::NewLine
    }

    return [PSCustomObject]@{
        Repository = $root
        Branch     = $branch
        Remote     = $RemoteName
        Provider   = $provider
        Url        = $safeUrl
        Passed     = ($result.ExitCode -eq 0)
        ExitCode   = $result.ExitCode
        Message    = $message
    }
}
