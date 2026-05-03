function Remove-GEOldLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Directory,

        [int]$RetentionDays = 30
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return
    }

    if ($RetentionDays -le 0) {
        return
    }

    $cutoff = (Get-Date).AddDays(-1 * $RetentionDays)

    $oldFiles = @(
        Get-ChildItem -LiteralPath $Directory -Filter '*.log' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff }
    )

    foreach ($file in $oldFiles) {
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
    }
}
