function Start-GELogSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [string]$Repository = '',

        [string]$Branch = '',

        [string]$LogPath,

        [int]$RetentionDays = 30
    )

    $logDirectory = Get-GELogPath -OverridePath $LogPath

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }

    Remove-GEOldLog -Directory $logDirectory -RetentionDays $RetentionDays -ErrorAction SilentlyContinue

    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $fileName = "$Command-$stamp.log"
    $filePath = Join-Path $logDirectory $fileName

    $moduleVersion = ''
    $module = Get-Module GitEasy | Select-Object -First 1
    if ($module) {
        $moduleVersion = $module.Version.ToString()
    }

    $headerLines = @(
        "GitEasy $Command session",
        ('=' * 60),
        "Time UTC:    $((Get-Date).ToUniversalTime().ToString('o'))",
        "Command:     $Command",
        "Repository:  $Repository",
        "Branch:      $Branch",
        "PowerShell:  $($PSVersionTable.PSVersion)",
        "GitEasy:     $moduleVersion",
        ''
    )

    [System.IO.File]::WriteAllLines(
        $filePath,
        $headerLines,
        [System.Text.UTF8Encoding]::new($false)
    )

    return [PSCustomObject]@{
        Path     = $filePath
        Command  = $Command
        Started  = (Get-Date).ToUniversalTime()
    }
}
