function Invoke-GEGit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ArgumentList,

        [string]$WorkingDirectory = (Get-Location).Path,

        [switch]$AllowFailure,

        [string]$LogPath = ''
    )

    $previousLocation = Get-Location

    try {
        Set-Location -LiteralPath $WorkingDirectory

        $previousActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'

        $merged = & git @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE

        $ErrorActionPreference = $previousActionPreference
    }
    finally {
        $ErrorActionPreference = 'Stop'
        Set-Location -LiteralPath $previousLocation
    }

    $stdoutLines = New-Object System.Collections.Generic.List[string]
    $stderrLines = New-Object System.Collections.Generic.List[string]

    foreach ($entry in @($merged)) {
        if ($null -eq $entry) { continue }

        if ($entry -is [System.Management.Automation.ErrorRecord]) {
            $stderrLines.Add($entry.ToString())
        }
        else {
            $stdoutLines.Add($entry.ToString())
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
        $stepText = 'git ' + ($ArgumentList -join ' ')

        $logLines = New-Object System.Collections.Generic.List[string]
        foreach ($line in $stdoutLines) {
            $logLines.Add($line)
        }
        foreach ($line in $stderrLines) {
            $logLines.Add('[stderr] ' + $line)
        }

        Add-GELogStep -Path $LogPath -Step $stepText -ExitCode $exitCode -Output $logLines
    }

    if (($exitCode -ne 0) -and (-not $AllowFailure)) {
        $combined = New-Object System.Collections.Generic.List[string]
        foreach ($line in $stdoutLines) { $combined.Add($line) }
        foreach ($line in $stderrLines) { $combined.Add($line) }

        throw ("git " + ($ArgumentList -join ' ') + " exited with code $exitCode" + [Environment]::NewLine + ($combined -join [Environment]::NewLine))
    }

    [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = @($stdoutLines)
        Stderr   = @($stderrLines)
    }
}
