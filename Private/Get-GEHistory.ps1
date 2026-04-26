function Get-GEHistory {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 200)]
        [int]$Count = 20,

        [string]$Path = (Get-Location).Path
    )

    $root = Get-GERepoRoot -Path $Path
    $result = Invoke-GEGit -ArgumentList @('log', "--max-count=$Count", '--date=short', '--pretty=format:%h%x09%ad%x09%an%x09%s') -WorkingDirectory $root -AllowFailure

    if ($result.ExitCode -ne 0) {
        return @()
    }

    foreach ($line in @($result.Output)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $parts = @($line -split "`t", 4)

        if ($parts.Count -eq 4) {
            [PSCustomObject]@{
                Repository = $root
                Hash       = $parts[0]
                Date       = $parts[1]
                Author     = $parts[2]
                Message    = $parts[3]
            }
        }
    }
}
