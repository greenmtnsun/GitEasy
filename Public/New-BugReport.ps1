function New-BugReport {
    <#
    .SYNOPSIS
    Open a pre-filled GitHub bug report for GitEasy in your web browser.

    .DESCRIPTION
    New-BugReport opens the GitEasy "new issue" page in your browser with the report already started for you: a short set of questions to answer, a snapshot of your setup (operating system, PowerShell, Git, and GitEasy versions), and an excerpt from your most recent diagnostic log. Passwords and web addresses are already removed from those logs before they are ever written, so the excerpt is safe to share.

    Nothing is sent anywhere on its own. The page simply opens with the details filled in; you read it over, add anything you like, and submit it yourself.

    If the report would be very long, the log excerpt is left out and the report instead points at the log file so you can attach it by hand.

    .PARAMETER NoLog
    Leave the diagnostic log excerpt out of the report entirely.

    .PARAMETER LogPath
    Override the directory the diagnostic logs are read from and where this run's log is written. Defaults to %LOCALAPPDATA%\GitEasy\Logs.

    .EXAMPLE
    New-BugReport

    .EXAMPLE
    New-BugReport -NoLog

    .EXAMPLE
    New-BugReport -WhatIf

    .NOTES
    Safety:
    - Opens a page with details filled in; never submits anything for you.
    - Log excerpts have passwords and web addresses removed before they are written.

    Steps:
    1. Start a diagnostic log session.
    2. Collect a small, safe snapshot of your setup.
    3. Find your most recent earlier diagnostic log, unless -NoLog was given.
    4. Build the report title and body, trimming the log excerpt if the report gets too long.
    5. Handle WhatIf and return the link without opening it if applicable.
    6. Open the pre-filled report in your browser and return a structured result.

    .LINK
    Show-Diagnostic

    .LINK
    Enable-GitEasy
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [switch]$NoLog,

        [Parameter()]
        [string]$LogPath = ''
    )

    $session = Start-GELogSession -Command 'New-BugReport' -LogPath $LogPath

    $userMessageOnFailure = 'Could not open a bug report.'

    # Keep the whole link comfortably inside what browsers accept.
    $maxUrlLength = 7000
    $issueBase = 'https://github.com/greenmtnsun/GitEasy/issues/new'

    try {
        $info = Get-GEEnvironmentInfo -LogPath $session.Path

        $logExcerpt = ''
        $logSourcePath = ''
        if (-not $NoLog) {
            $logDir = Get-GELogPath -OverridePath $LogPath
            if (Test-Path -LiteralPath $logDir -PathType Container) {
                $priorLog = @(
                    Get-ChildItem -LiteralPath $logDir -Filter '*.log' -File -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -ne $session.Path } |
                        Sort-Object LastWriteTime -Descending
                ) | Select-Object -First 1

                if ($priorLog) {
                    $logSourcePath = $priorLog.FullName
                    $logLines = @([System.IO.File]::ReadAllLines($priorLog.FullName))
                    $tail = @($logLines | Select-Object -Last 60)
                    $logExcerpt = ($tail -join [Environment]::NewLine)
                }
            }
        }

        $title = "Bug report: GitEasy $($info.GitEasyVersion)"

        $bodyLines = New-Object System.Collections.Generic.List[string]
        $bodyLines.Add('Thanks for reporting a GitEasy problem. Please fill in the three sections below.')
        $bodyLines.Add('')
        $bodyLines.Add('## What were you doing?')
        $bodyLines.Add('')
        $bodyLines.Add('')
        $bodyLines.Add('## What happened?')
        $bodyLines.Add('')
        $bodyLines.Add('')
        $bodyLines.Add('## What did you expect instead?')
        $bodyLines.Add('')
        $bodyLines.Add('')
        $bodyLines.Add('## Your setup (filled in automatically)')
        $bodyLines.Add("- Operating system: $($info.OperatingSystem)")
        $bodyLines.Add("- PowerShell: $($info.PowerShellVersion) ($($info.PowerShellEdition))")
        $bodyLines.Add("- Git: $($info.GitVersion)")
        $bodyLines.Add("- GitEasy: $($info.GitEasyVersion)")

        # Assemble the body, dropping the log excerpt if it would push the link past the limit.
        $logIncluded = $false
        $bodyWithLog = New-Object System.Collections.Generic.List[string]
        foreach ($line in $bodyLines) { $bodyWithLog.Add($line) }
        if (-not [string]::IsNullOrWhiteSpace($logExcerpt)) {
            $bodyWithLog.Add('')
            $bodyWithLog.Add('## Most recent diagnostic log (passwords already removed)')
            $bodyWithLog.Add('```')
            $bodyWithLog.Add($logExcerpt)
            $bodyWithLog.Add('```')
        }

        $candidateBody = ($bodyWithLog -join [Environment]::NewLine)
        $candidateUrl = $issueBase + '?title=' + [uri]::EscapeDataString($title) + '&body=' + [uri]::EscapeDataString($candidateBody)

        if (($candidateUrl.Length -le $maxUrlLength) -and (-not [string]::IsNullOrWhiteSpace($logExcerpt))) {
            $finalBody = $candidateBody
            $logIncluded = $true
        }
        else {
            $shortBody = New-Object System.Collections.Generic.List[string]
            foreach ($line in $bodyLines) { $shortBody.Add($line) }
            if (-not [string]::IsNullOrWhiteSpace($logSourcePath)) {
                $shortBody.Add('')
                $shortBody.Add('## Diagnostic log')
                $shortBody.Add('The log was too long to include here. Please attach this file:')
                $shortBody.Add($logSourcePath)
                $shortBody.Add('(Run Show-Diagnostic to open it.)')
            }
            $finalBody = ($shortBody -join [Environment]::NewLine)
        }

        $url = $issueBase + '?title=' + [uri]::EscapeDataString($title) + '&body=' + [uri]::EscapeDataString($finalBody)
        Add-GELogStep -Path $session.Path -Step "Bug report link built (log included: $logIncluded)" -ExitCode 0

        if (-not $PSCmdlet.ShouldProcess('your web browser', 'Open a pre-filled GitEasy bug report')) {
            Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS' -UserMessage 'Skipped (WhatIf).'
            return [PSCustomObject]@{
                Url         = $url
                LogIncluded = $logIncluded
                Environment = $info
                Message     = 'Skipped (WhatIf). The link was prepared but not opened.'
            }
        }

        if ($env:OS -eq 'Windows_NT') {
            Start-Process -FilePath $url
            Write-Host 'A pre-filled bug report just opened in your browser. Review it, then submit.'
        }
        else {
            Write-Host 'Open this pre-filled bug report in your browser, then submit:'
            Write-Host $url
        }

        $result = [PSCustomObject]@{
            Url         = $url
            LogIncluded = $logIncluded
            Environment = $info
            Message     = 'Pre-filled bug report ready.'
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
