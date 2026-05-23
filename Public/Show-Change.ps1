function Show-Change {
    <#
    .SYNOPSIS
    Show what has changed in your project folder.

    .DESCRIPTION
    Show-Change is the natural counterpart to Find-CodeChange. Where Find-CodeChange tells you HOW MANY things changed and which files, Show-Change tells you the actual changes - the lines added and removed.

    By default, Show-Change returns the changes you have not yet saved (working area vs last saved point), one structured object per file with Path and Diff. Pipe to Format-List for the full text. With -NextSave, it shows changes that are already prepared for the next saved point. With -Compact, it returns a one-line summary per file instead of the full text.

    .PARAMETER Path
    Filter to a single file (relative to the project root or absolute). Without this, every changed file is included.

    .PARAMETER NextSave
    Show only the changes that are already prepared for the next saved point, instead of the working-area changes you have not yet added.

    .PARAMETER Compact
    Return a one-line summary per file (file name, lines added, lines removed) instead of the full diff text.

    .PARAMETER LogPath
    Override the directory where the diagnostic log for this run is written.

    .EXAMPLE
    Show-Change

    .EXAMPLE
    Show-Change -Path 'README.md'

    .EXAMPLE
    Show-Change -NextSave

    .EXAMPLE
    Show-Change -Compact

    .NOTES
    Read-only. Does not modify anything in the project. Use Find-CodeChange for a count summary; Show-Change for the actual diff text.

    .LINK
    Find-CodeChange

    .LINK
    Save-Work

    .LINK
    Show-History
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '',

        [Parameter()]
        [switch]$NextSave,

        [Parameter()]
        [switch]$Compact,

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

    $session = Start-GELogSession -Command 'Show-Change' -Repository ([string]$repoRoot) -LogPath $LogPath

    $userMessageOnFailure = 'Could not show changes.'

    try {
        if (-not $repoRoot) {
            throw 'This folder is not inside a saveable workspace. Move into your project folder first.'
        }

        if ($Compact) {
            $statArgs = @('diff', '--stat')
            if ($NextSave) { $statArgs += '--cached' }
            if ($Path)   { $statArgs += '--' ; $statArgs += $Path }

            $statResult = Invoke-GEGit -ArgumentList $statArgs -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
            $summaryLines = @($statResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

            $result = [PSCustomObject]@{
                Repository = $repoRoot
                NextSave   = [bool]$NextSave
                Summary    = ($summaryLines -join "`r`n")
            }

            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
            return $result
        }

        # Full per-file diff
        $nameOnlyArgs = @('diff', '--name-only')
        if ($NextSave) { $nameOnlyArgs += '--cached' }
        if ($Path)   { $nameOnlyArgs += '--' ; $nameOnlyArgs += $Path }

        $namesResult = Invoke-GEGit -ArgumentList $nameOnlyArgs -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
        $changedFiles = @($namesResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

        $entries = New-Object System.Collections.Generic.List[object]

        foreach ($file in $changedFiles) {
            $diffArgs = @('diff')
            if ($NextSave) { $diffArgs += '--cached' }
            $diffArgs += '--'
            $diffArgs += $file

            $diffResult = Invoke-GEGit -ArgumentList $diffArgs -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
            $diffText = ($diffResult.Output -join "`r`n")

            $entries.Add([PSCustomObject]@{
                Repository = $repoRoot
                Path       = $file
                NextSave   = [bool]$NextSave
                Diff       = $diffText
            })
        }

        Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
        return $entries.ToArray()
    }
    catch {
        $err = $_
        $innerMessage = $err.Exception.Message
        $finalMsg = if ($innerMessage -like 'git *') { $userMessageOnFailure } else { $innerMessage }
        Complete-GELogSession -Path $session.Path -Outcome 'FAILURE' -UserMessage $finalMsg -ErrorMessage $innerMessage
        throw "$finalMsg Details: $($session.Path)"
    }
}
