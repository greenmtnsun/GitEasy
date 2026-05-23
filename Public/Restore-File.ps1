function Restore-File {
    <#
    .SYNOPSIS
    Restore a single file to its last saved state without touching anything else.

    .DESCRIPTION
    Restore-File is the targeted GitEasy restore. It resets one file to its last saved version while leaving every other change in the active working area alone.

    Use it when you want a precise rollback of one file - for example, a generated file you accidentally edited, or a configuration file you want to revert without abandoning the rest of your work.

    Each invocation writes a self-contained diagnostic log file. Successful runs log silently; failures throw a plain-English message and point at the log file with the technical detail.

    .PARAMETER Path
    Path to the file to restore. Can be relative to the current location or absolute. Must be a tracked file in the active project.

    .PARAMETER LogPath
    Override the directory where the diagnostic log for this run is written.

    .EXAMPLE
    Restore-File -Path README.md

    .EXAMPLE
    Find-CodeChange; Restore-File -Path Public\Save-Work.ps1; Find-CodeChange

    .NOTES
    Safety:
    - Refuses to run during an unfinished merge, rebase, cherry-pick, revert, or bisect.
    - Refuses to run while there are unfinished conflicts.
    - Refuses to operate on a file that does not exist or is not tracked.
    - Run Save-Work -NoPush first if you might want the discarded edits later.

    .LINK
    Find-CodeChange

    .LINK
    Undo-Changes

    .LINK
    Save-Work
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

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

    $session = Start-GELogSession -Command 'Restore-File' -Repository ([string]$repoRoot) -LogPath $LogPath

    $userMessageOnFailure = "Could not restore '$Path'."

    try {
        Assert-GESafeSave -Path ([string]$repoRoot) -LogPath $session.Path | Out-Null

        if (-not $repoRoot) {
            $rootResult = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -LogPath $session.Path
            $repoRoot = $rootResult.Output | Select-Object -First 1
        }

        $lsResult = Invoke-GEGit -ArgumentList @('ls-files', '--error-unmatch', '--', $Path) -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
        if ($lsResult.ExitCode -ne 0) {
            throw "'$Path' is not a saved file in this project. Check the path and try again."
        }

        if (-not $PSCmdlet.ShouldProcess($Path, 'Restore to last saved state')) {
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS' -UserMessage 'Skipped (WhatIf).'
            return
        }

        Invoke-GEGit -ArgumentList @('checkout', '--', $Path) -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null

        Write-Host "Restored '$Path' to its last saved state."

        $result = [PSCustomObject]@{
            Repository = $repoRoot
            Path       = $Path
            Message    = "'$Path' was restored to its last saved state."
        }

        Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
        return $result
    }
    catch {
        $err = $_

        $innerMessage = $err.Exception.Message
        if ($innerMessage -like 'git *') {
            $finalMsg = $userMessageOnFailure
        }
        else {
            $finalMsg = $innerMessage
        }

        Complete-GELogSession -Path $session.Path -Outcome 'FAILURE' -UserMessage $finalMsg -ErrorMessage $innerMessage

        throw "$finalMsg Details: $($session.Path)"
    }
}
