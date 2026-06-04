function Get-GELogPath {
    <#
    .SYNOPSIS
    Resolve the directory where GitEasy diagnostic logs should be written.

    .DESCRIPTION
    Resolution order: -OverridePath parameter, then GITEASY_LOG_PATH environment variable, then %LOCALAPPDATA%\GitEasy\Logs.

    .PARAMETER OverridePath
    Explicit path that wins over both the env var and the default.

    .EXAMPLE
    $dir = Get-GELogPath

    .EXAMPLE
    $dir = Get-GELogPath -OverridePath 'D:\diagnostics'

    .NOTES
    Internal. No I/O.

    Steps:
    1. Return the -OverridePath value if it was provided.
    2. Return the GITEASY_LOG_PATH environment variable value if it is set.
    3. Otherwise return the default path under %LOCALAPPDATA%\GitEasy\Logs.

    .LINK
    Show-Diagnostic

    .LINK
    Start-GELogSession
    #>
    [CmdletBinding()]
    param(
        [string]$OverridePath
    )

    if (-not [string]::IsNullOrWhiteSpace($OverridePath)) {
        return $OverridePath
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GITEASY_LOG_PATH)) {
        return $env:GITEASY_LOG_PATH
    }

    $localAppData = $env:LOCALAPPDATA
    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        $localAppData = Join-Path $env:USERPROFILE 'AppData\Local'
    }

    return (Join-Path $localAppData 'GitEasy\Logs')
}
