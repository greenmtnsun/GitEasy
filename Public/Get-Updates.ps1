function Get-Updates {
    <#
    .SYNOPSIS
    Get the latest updates from where the project is published, without merging them.

    .DESCRIPTION
    Get-Updates checks the published location for new saved points that other people have added since you last looked, and downloads them locally without changing your working area. It is the safe "what's new on the team's side" command - it never merges, never overwrites your work, and never publishes anything.

    Use it before Save-Work when you want to know whether a teammate has pushed new changes. The returned object reports how many new saved points were fetched. To incorporate them into your active working area, use Save-Work (which pulls with rebase before publishing) or stay outside Save-Work entirely if you just wanted to look.

    .PARAMETER RemoteName
    The name of the published location to check. Defaults to origin.

    .PARAMETER LogPath
    Override the directory where the diagnostic log for this run is written.

    .EXAMPLE
    Get-Updates

    .EXAMPLE
    Get-Updates -RemoteName origin

    .NOTES
    Read-only with respect to your working area. Does fetch from the remote, which writes new objects to your local Git database; Save-Work decides whether and how those updates are applied.

    .LINK
    Save-Work

    .LINK
    Show-Remote

    .LINK
    Test-Login
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$RemoteName = 'origin',

        [Parameter()]
        [string]$LogPath = ''
    )

    $repoRoot = $null
    try {
        $rootProbe = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -AllowFailure
        if ($rootProbe.ExitCode -eq 0) {
            $repoRoot = $rootProbe.Output | Select-Object -First 1
        }
    }
    catch {
        $repoRoot = $null
    }

    $session = Start-GELogSession -Command 'Get-Updates' -Repository ([string]$repoRoot) -LogPath $LogPath

    $userMessageOnFailure = 'Could not get updates.'

    try {
        if (-not $repoRoot) {
            throw 'This folder is not inside a saveable workspace. Move into your project folder first.'
        }

        # Verify the named remote exists
        $remoteResult = Invoke-GEGit -ArgumentList @('remote') -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
        $remotes = @($remoteResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

        if ($remotes.Count -eq 0) {
            throw 'No published location is configured. Use Set-Token or Set-Ssh to add one.'
        }

        if (-not ($remotes -contains $RemoteName)) {
            throw "No published location named '$RemoteName' is configured. Available: $($remotes -join ', ')."
        }

        # Determine the active working area (so we can count new commits on it)
        $branch = ''
        $branchResult = Invoke-GEGit -ArgumentList @('symbolic-ref', '--short', 'HEAD') -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
        if ($branchResult.ExitCode -eq 0) {
            $branch = $branchResult.Output | Select-Object -First 1
        }

        # Snapshot the remote ref before fetch
        $beforeSha = ''
        if ($branch) {
            $beforeRef = Invoke-GEGit -ArgumentList @('rev-parse', "$RemoteName/$branch") -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
            if ($beforeRef.ExitCode -eq 0) {
                $beforeSha = $beforeRef.Output | Select-Object -First 1
            }
        }

        $userMessageOnFailure = "Could not fetch updates from '$RemoteName'."

        Invoke-GEGit -ArgumentList @('fetch', $RemoteName) -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null

        # Snapshot the remote ref after fetch and count new saved points
        $newCount = 0
        if ($branch) {
            $afterRef = Invoke-GEGit -ArgumentList @('rev-parse', "$RemoteName/$branch") -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
            $afterSha = ''
            if ($afterRef.ExitCode -eq 0) {
                $afterSha = $afterRef.Output | Select-Object -First 1
            }

            if ($beforeSha -and $afterSha -and ($beforeSha -ne $afterSha)) {
                $countResult = Invoke-GEGit -ArgumentList @('rev-list', '--count', "$beforeSha..$afterSha") -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
                if ($countResult.ExitCode -eq 0) {
                    $countVal = ($countResult.Output | Select-Object -First 1) -as [int]
                    if ($null -ne $countVal) { $newCount = $countVal }
                }
            }
        }

        $message = if ($newCount -eq 0) {
            "No new saved points on '$RemoteName'."
        }
        elseif ($newCount -eq 1) {
            "1 new saved point fetched from '$RemoteName'. Run Save-Work to incorporate it."
        }
        else {
            "$newCount new saved points fetched from '$RemoteName'. Run Save-Work to incorporate them."
        }

        Write-Host $message

        $result = [PSCustomObject]@{
            Repository     = $repoRoot
            Remote         = $RemoteName
            Branch         = $branch
            NewSavedPoints = $newCount
            Message        = $message
        }

        Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
        return $result
    }
    catch {
        $err = $_
        $innerMessage = $err.Exception.Message
        $finalMsg = if ($innerMessage -like 'git *') { $userMessageOnFailure } else { $innerMessage }
        Complete-GELogSession -Path $session.Path -Outcome 'FAILURE' -UserMessage $finalMsg -ErrorMessage $innerMessage
        throw "$finalMsg Details: $($session.Path)"
    }
}
