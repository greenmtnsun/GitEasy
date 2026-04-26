function Show-History {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 200)]
        [int]$Count = 20
    )

    $history = @(Get-GEHistory -Count $Count)

    if ($history.Count -eq 0) {
        return [PSCustomObject]@{
            Repository = Get-GERepoRoot
            Message    = 'No commit history found.'
        }
    }

    return $history
}
