function Undo-Changes {
    <#
    .SYNOPSIS
    Throw away unsaved changes and return the working area to its last saved state.

    .DESCRIPTION
    Undo-Changes is the GitEasy-first way to abandon every unsaved edit. Because the operation is destructive, the command refuses to run without explicit confirmation: pass -Force, or accept the standard PowerShell -Confirm prompt.

    For a softer alternative, Save-Work -NoPush will save the current state locally first, so you can recover later if you change your mind.

    Each invocation writes a self-contained diagnostic log file. Successful runs log silently; failures throw a plain-English message and point at the log file with the technical detail.

    .PARAMETER Force
    Skip the confirmation prompt and discard unsaved changes immediately.

    .PARAMETER LogPath
    Override the directory where the diagnostic log for this run is written.

    .EXAMPLE
    Find-CodeChange; Undo-Changes -Force

    .EXAMPLE
    Save-Work 'checkpoint before undo' -NoPush; Undo-Changes -Force

    .NOTES
    Safety:
    - Always run Find-CodeChange first to see what will be discarded.
    - Use Save-Work -NoPush for a recoverable checkpoint before undoing.
    - Refuses to run during an unfinished merge, rebase, cherry-pick, revert, or bisect.
    - Refuses to run while there are unfinished conflicts.

    .LINK
    Find-CodeChange

    .LINK
    Restore-File

    .LINK
    Save-Work
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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

    $session = Start-GELogSession -Command 'Undo-Changes' -Repository ([string]$repoRoot) -LogPath $LogPath

    $userMessageOnFailure = 'Could not undo changes.'

    try {
        Assert-GESafeSave -Path ([string]$repoRoot) -LogPath $session.Path | Out-Null

        if (-not $repoRoot) {
            $rootResult = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -LogPath $session.Path
            $repoRoot = $rootResult.Output | Select-Object -First 1
        }

        $statusResult = Invoke-GEGit -ArgumentList @('status', '--porcelain=v1') -WorkingDirectory $repoRoot -LogPath $session.Path
        $statusLines = @($statusResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

        if ($statusLines.Count -eq 0) {
            Write-Host 'Nothing to undo. The active working area is already clean.'

            $result = [PSCustomObject]@{
                Repository = $repoRoot
                Discarded  = 0
                Message    = 'Nothing to undo.'
            }

            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
            return $result
        }

        $hasExplicitOptIn = $Force -or $PSBoundParameters.ContainsKey('Confirm') -or $PSBoundParameters.ContainsKey('WhatIf')
        if (-not $hasExplicitOptIn) {
            throw "Refusing to discard unsaved changes without confirmation. Re-run with -Force to skip the prompt, pass -Confirm to be prompted explicitly, use -WhatIf to preview, or use Save-Work -NoPush first to keep a recoverable checkpoint."
        }

        if (-not $Force) {
            if (-not $PSCmdlet.ShouldProcess($repoRoot, "Discard $($statusLines.Count) unsaved change(s) - this cannot be reversed")) {
                Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS' -UserMessage 'Skipped (Confirm declined or WhatIf).'
                return
            }
        }

        Invoke-GEGit -ArgumentList @('checkout', '--', '.') -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null
        Invoke-GEGit -ArgumentList @('clean', '-fd') -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null

        Write-Host "Discarded $($statusLines.Count) unsaved change(s)."

        $result = [PSCustomObject]@{
            Repository = $repoRoot
            Discarded  = $statusLines.Count
            Message    = "Discarded $($statusLines.Count) unsaved change(s)."
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
