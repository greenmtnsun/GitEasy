function Get-GELogPath {
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
