function Show-Diagnostic {
    <#
    .SYNOPSIS
    Open or list the diagnostic log files written by GitEasy.

    .DESCRIPTION
    Every GitEasy command writes a small log file describing exactly what happened during that run. Show-Diagnostic gives you a friendly way to find and open those logs without knowing where they live.

    With no parameters, Show-Diagnostic opens the most recent log in the default editor. With -List, it prints a table of recent logs with timestamps and sizes. With -All, it opens the logs folder in Explorer.

    .PARAMETER List
    Print a table of recent logs. Use with -Count to control how many.

    .PARAMETER All
    Open the logs folder in Explorer.

    .PARAMETER Count
    With -List, the maximum number of log entries to print. Defaults to 10.

    .PARAMETER LogPath
    Override the directory to look in. Defaults to %LOCALAPPDATA%\GitEasy\Logs and can be overridden site-wide through the GITEASY_LOG_PATH environment variable.

    .EXAMPLE
    Show-Diagnostic

    .EXAMPLE
    Show-Diagnostic -List

    .EXAMPLE
    Show-Diagnostic -List -Count 5

    .EXAMPLE
    Show-Diagnostic -All

    .NOTES
    Logs older than 30 days are automatically pruned each time a new log is written. To send a log to a colleague, attach the file directly - it is self-contained.

    Steps:
    1. Resolve the log directory from the parameter, the environment variable, or the default location.
    2. If the directory does not exist, report that no logs have been written yet and return.
    3. If -All is set, open the logs folder in Explorer (or print the path on non-Windows) and return.
    4. Load all log files sorted newest first.
    5. If -List is set, return a table of the most recent logs up to the requested count.
    6. Otherwise, open the most recent log file in the default editor.

    .LINK
    Save-Work

    .LINK
    Test-Login
    #>
    [CmdletBinding(DefaultParameterSetName = 'Open')]
    [OutputType([System.Void])]
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
        if ($env:OS -eq 'Windows_NT') {
            Start-Process -FilePath 'explorer.exe' -ArgumentList $logDirectory
        }
        else {
            Write-Host "Logs folder: $logDirectory"
        }
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

    if ($env:OS -eq 'Windows_NT') {
        Start-Process -FilePath $mostRecent.FullName
    }
    else {
        Write-Host "Open this file in your editor: $($mostRecent.FullName)"
    }
}
