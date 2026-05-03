function Show-Diagnostic {
    [CmdletBinding(DefaultParameterSetName = 'Open')]
    param(
        [Parameter(ParameterSetName = 'List')]
        [switch]$List,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List')]
        [int]$Count = 10,

        [Parameter()]
        [string]$LogPath
    )

    $logDirectory = Get-GELogPath -OverridePath $LogPath

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        Write-Host "No diagnostic logs yet. Folder will be created on first failure: $logDirectory"
        return
    }

    if ($All) {
        Start-Process -FilePath 'explorer.exe' -ArgumentList $logDirectory
        return
    }

    $allLogs = @(
        Get-ChildItem -LiteralPath $logDirectory -Filter '*.log' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
    )

    if ($allLogs.Count -eq 0) {
        Write-Host "No diagnostic logs found in $logDirectory."
        return
    }

    if ($List) {
        $top = $allLogs | Select-Object -First $Count

        $rows = foreach ($log in $top) {
            [PSCustomObject]@{
                Name        = $log.Name
                LastWritten = $log.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                SizeKB      = [math]::Round($log.Length / 1KB, 2)
            }
        }

        return $rows
    }

    $mostRecent = $allLogs | Select-Object -First 1
    Write-Host "Opening: $($mostRecent.FullName)"

    Start-Process -FilePath $mostRecent.FullName
}
