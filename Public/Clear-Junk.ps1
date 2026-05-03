function Clear-Junk {
    <#
    .SYNOPSIS
    Find or remove obvious temporary files in the active project folder.

    .DESCRIPTION
    Clear-Junk identifies untracked files that match common "junk" patterns - editor backups, build leftovers, swap files - and either lists them or removes them, depending on whether you pass -Force.

    By default, Clear-Junk is a dry run: it returns a list of candidate files but removes nothing. Pass -Force to actually delete them. Tracked files are never touched even with -Force.

    Each invocation writes a self-contained diagnostic log file. Successful runs log silently; failures throw a plain-English message and point at the log file with the technical detail.

    .PARAMETER Force
    Actually remove the candidate files. Without this switch, Clear-Junk only lists what it would remove.

    .PARAMETER LogPath
    Override the directory where the diagnostic log for this run is written.

    .EXAMPLE
    Clear-Junk

    .EXAMPLE
    Clear-Junk -Force

    .EXAMPLE
    Find-CodeChange; Clear-Junk; Find-CodeChange

    .NOTES
    Junk patterns: *.bak, *.tmp, *.swp, *~ (editor backups), and Thumbs.db.

    Safety:
    - Default is a dry run; never deletes without -Force.
    - Tracked files are never touched.
    - Refuses to run during an unfinished merge, rebase, cherry-pick, revert, or bisect.
    - Run Find-CodeChange before and after to inspect the result.

    .LINK
    Find-CodeChange

    .LINK
    Save-Work

    .LINK
    Undo-Changes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$Force,

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

    $session = Start-GELogSession -Command 'Clear-Junk' -Repository ([string]$repoRoot) -LogPath $LogPath

    $userMessageOnFailure = 'Could not scan for junk files.'

    try {
        Assert-GESafeSave -Path ([string]$repoRoot) -LogPath $session.Path | Out-Null

        if (-not $repoRoot) {
            $rootResult = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -LogPath $session.Path
            $repoRoot = $rootResult.Output | Select-Object -First 1
        }

        $junkPatterns = @('*.bak', '*.tmp', '*.swp', '*~', 'Thumbs.db')

        $statusResult = Invoke-GEGit -ArgumentList @('status', '--porcelain=v1') -WorkingDirectory $repoRoot -LogPath $session.Path
        $untracked = @()
        foreach ($line in $statusResult.Output) {
            if ($line -match '^\?\?\s+(.+)$') {
                $untracked += $Matches[1].Trim('"')
            }
        }

        $candidates = New-Object System.Collections.Generic.List[string]
        foreach ($file in $untracked) {
            $name = Split-Path -Path $file -Leaf
            foreach ($pattern in $junkPatterns) {
                if ($name -like $pattern) {
                    $candidates.Add($file)
                    break
                }
            }
        }

        if ($candidates.Count -eq 0) {
            Write-Host 'No junk files found.'
            $result = [PSCustomObject]@{
                Repository = $repoRoot
                Candidates = @()
                Removed    = 0
                Message    = 'No junk files found.'
            }
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
            return $result
        }

        if (-not $Force) {
            Write-Host "Found $($candidates.Count) junk file(s). Re-run with -Force to remove them:"
            foreach ($c in $candidates) {
                Write-Host "  $c"
            }
            $result = [PSCustomObject]@{
                Repository = $repoRoot
                Candidates = @($candidates)
                Removed    = 0
                Message    = "$($candidates.Count) candidate(s) found. Pass -Force to remove."
            }
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
            return $result
        }

        if (-not $PSCmdlet.ShouldProcess($repoRoot, "Remove $($candidates.Count) junk file(s)")) {
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS' -UserMessage 'Skipped (WhatIf).'
            return
        }

        $removed = 0
        foreach ($c in $candidates) {
            $full = Join-Path $repoRoot $c
            if (Test-Path -LiteralPath $full -PathType Leaf) {
                Remove-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                    $removed++
                }
            }
        }

        Write-Host "Removed $removed junk file(s)."

        $result = [PSCustomObject]@{
            Repository = $repoRoot
            Candidates = @($candidates)
            Removed    = $removed
            Message    = "Removed $removed junk file(s)."
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
