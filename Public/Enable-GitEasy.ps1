function Enable-GitEasy {
    <#
    .SYNOPSIS
    Make GitEasy load automatically every time you open PowerShell.

    .DESCRIPTION
    Enable-GitEasy adds a small, clearly marked block to your personal PowerShell startup file so the plain-English GitEasy commands are ready in every new session. After this, you never have to load GitEasy by hand again. The block only loads GitEasy if it is installed, so it stays safe even if you later move or remove the module.

    GitEasy is built to be the everyday way you save and publish your work. The one thing it deliberately leaves to a person is a merge conflict — when two saves clash, GitEasy stops and tells you which files need a human, rather than guessing.

    Running this more than once is safe: if the block is already present, Enable-GitEasy reports that and changes nothing. To undo it, run Disable-GitEasy.

    Each invocation writes a self-contained diagnostic log file. Successful runs log silently; failures throw a plain-English message and point at the log file.

    .PARAMETER ProfilePath
    Override the startup file to write to. Defaults to your personal all-hosts PowerShell startup file. Mainly for testing.

    .PARAMETER LogPath
    Override the directory where the diagnostic log for this run is written. Defaults to %LOCALAPPDATA%\GitEasy\Logs.

    .EXAMPLE
    Enable-GitEasy

    .EXAMPLE
    Enable-GitEasy -WhatIf

    .NOTES
    Safety:
    - Writes only a clearly marked block; never edits the rest of your startup file.
    - Safe to run repeatedly; does nothing if the block is already present.
    - Fully reversible with Disable-GitEasy.

    Steps:
    1. Start a diagnostic log session.
    2. Resolve the startup file path and make sure its folder exists.
    3. If the GitEasy block is already present, report that and stop.
    4. Handle WhatIf and return early if applicable.
    5. Append the marked GitEasy load block to the startup file.
    6. Tell the user it worked and return a structured result.

    .LINK
    Disable-GitEasy

    .LINK
    New-BugReport
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$ProfilePath = '',

        [Parameter()]
        [string]$LogPath = ''
    )

    $session = Start-GELogSession -Command 'Enable-GitEasy' -LogPath $LogPath

    $userMessageOnFailure = 'Could not set GitEasy to load automatically.'

    try {
        $targetProfile = Get-GEProfilePath -OverridePath $ProfilePath
        Add-GELogStep -Path $session.Path -Step "Startup file: $targetProfile" -ExitCode 0

        $block = Get-GEProfileBlock

        $existing = ''
        if (Test-Path -LiteralPath $targetProfile -PathType Leaf) {
            $existing = [System.IO.File]::ReadAllText($targetProfile)
        }

        if ($existing -like "*$($block.Begin)*") {
            Write-Host 'GitEasy already loads automatically. Nothing to change.'

            $alreadyResult = [PSCustomObject]@{
                ProfilePath    = $targetProfile
                AlreadyEnabled = $true
                Message        = 'GitEasy was already set to load automatically.'
            }

            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
            return $alreadyResult
        }

        if (-not $PSCmdlet.ShouldProcess($targetProfile, 'Add the GitEasy auto-load block')) {
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS' -UserMessage 'Skipped (WhatIf).'
            return [PSCustomObject]@{
                ProfilePath    = $targetProfile
                AlreadyEnabled = $false
                Message        = 'Skipped (WhatIf).'
            }
        }

        $parentDir = Split-Path -Parent $targetProfile
        if (-not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path -LiteralPath $parentDir -PathType Container)) {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }

        $toWrite = New-Object System.Collections.Generic.List[string]
        if (-not [string]::IsNullOrWhiteSpace($existing)) {
            $toWrite.Add('')
        }
        foreach ($line in $block.Lines) {
            $toWrite.Add($line)
        }

        $sb = New-Object System.Text.StringBuilder
        foreach ($line in $toWrite) {
            [void]$sb.AppendLine($line)
        }

        [System.IO.File]::AppendAllText(
            $targetProfile,
            $sb.ToString(),
            [System.Text.UTF8Encoding]::new($false)
        )

        Write-Host 'Done. GitEasy will load automatically next time you open PowerShell.'
        Write-Host 'Your everyday commands: Save-Work, Find-CodeChange, Show-History, Show-Remote.'

        $result = [PSCustomObject]@{
            ProfilePath    = $targetProfile
            AlreadyEnabled = $false
            Message        = 'GitEasy will now load automatically in new sessions.'
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
