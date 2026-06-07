function Disable-GitEasy {
    <#
    .SYNOPSIS
    Stop GitEasy from loading automatically when you open PowerShell.

    .DESCRIPTION
    Disable-GitEasy removes the marked block that Enable-GitEasy added to your personal PowerShell startup file. After this, GitEasy no longer loads on its own; you can still use it any time by running Import-Module GitEasy. Only the GitEasy block is touched — the rest of your startup file is left exactly as it was.

    Running this when GitEasy is not set to auto-load is safe: it reports that there was nothing to remove and changes nothing.

    Each invocation writes a self-contained diagnostic log file. Successful runs log silently; failures throw a plain-English message and point at the log file.

    .PARAMETER ProfilePath
    Override the startup file to edit. Defaults to your personal all-hosts PowerShell startup file. Mainly for testing.

    .PARAMETER LogPath
    Override the directory where the diagnostic log for this run is written. Defaults to %LOCALAPPDATA%\GitEasy\Logs.

    .EXAMPLE
    Disable-GitEasy

    .EXAMPLE
    Disable-GitEasy -WhatIf

    .NOTES
    Safety:
    - Removes only the clearly marked GitEasy block; never touches the rest of your startup file.
    - Safe to run when nothing is set up; reports and stops.

    Steps:
    1. Start a diagnostic log session.
    2. Resolve the startup file path.
    3. If the file or the GitEasy block is not present, report that and stop.
    4. Handle WhatIf and return early if applicable.
    5. Remove the marked block (and the blank separator line before it).
    6. Tell the user it worked and return a structured result.

    .LINK
    Enable-GitEasy
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$ProfilePath = '',

        [Parameter()]
        [string]$LogPath = ''
    )

    $session = Start-GELogSession -Command 'Disable-GitEasy' -LogPath $LogPath

    $userMessageOnFailure = 'Could not stop GitEasy from loading automatically.'

    try {
        $targetProfile = Get-GEProfilePath -OverridePath $ProfilePath
        Add-GELogStep -Path $session.Path -Step "Startup file: $targetProfile" -ExitCode 0

        $block = Get-GEProfileBlock

        $notSetMessage = 'GitEasy was not set to load automatically. Nothing to remove.'

        if (-not (Test-Path -LiteralPath $targetProfile -PathType Leaf)) {
            Write-Host $notSetMessage
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
            return [PSCustomObject]@{
                ProfilePath     = $targetProfile
                AlreadyDisabled = $true
                Message         = $notSetMessage
            }
        }

        $lines = @([System.IO.File]::ReadAllLines($targetProfile))

        $beginIndex = -1
        $endIndex = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($beginIndex -lt 0 -and $lines[$i].Trim() -eq $block.Begin) {
                $beginIndex = $i
            }
            elseif ($beginIndex -ge 0 -and $lines[$i].Trim() -eq $block.End) {
                $endIndex = $i
                break
            }
        }

        if ($beginIndex -lt 0 -or $endIndex -lt 0) {
            Write-Host $notSetMessage
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
            return [PSCustomObject]@{
                ProfilePath     = $targetProfile
                AlreadyDisabled = $true
                Message         = $notSetMessage
            }
        }

        if (-not $PSCmdlet.ShouldProcess($targetProfile, 'Remove the GitEasy auto-load block')) {
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS' -UserMessage 'Skipped (WhatIf).'
            return [PSCustomObject]@{
                ProfilePath     = $targetProfile
                AlreadyDisabled = $false
                Message         = 'Skipped (WhatIf).'
            }
        }

        # Drop the blank separator line immediately before the block, if any.
        $removeFrom = $beginIndex
        if ($beginIndex -gt 0 -and [string]::IsNullOrWhiteSpace($lines[$beginIndex - 1])) {
            $removeFrom = $beginIndex - 1
        }

        $kept = New-Object System.Collections.Generic.List[string]
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -ge $removeFrom -and $i -le $endIndex) {
                continue
            }
            $kept.Add($lines[$i])
        }

        [System.IO.File]::WriteAllLines(
            $targetProfile,
            $kept,
            [System.Text.UTF8Encoding]::new($false)
        )

        Write-Host 'Done. GitEasy will no longer load automatically.'
        Write-Host 'You can still use it any time with: Import-Module GitEasy'

        $result = [PSCustomObject]@{
            ProfilePath     = $targetProfile
            AlreadyDisabled = $false
            Message         = 'GitEasy will no longer load automatically.'
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
