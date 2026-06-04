function Show-History {
    <#
    .SYNOPSIS
    Show recent saved points in a readable form.

    .DESCRIPTION
    Show-History returns the most recent saved points (commits) for the active project folder, with the short identifier, date, author, and message for each. Run it after Save-Work to confirm the saved point was recorded, or any time you want to inspect recent work.

    By default, Show-History returns structured objects you can pipe and filter. With -Graph, it prints a visual graph (with branching and merging) directly to the host instead - useful for seeing how working areas relate.

    .PARAMETER Count
    How many recent saved points to show. Defaults to 20. Validated to the range 1-200 so the output stays readable.

    .PARAMETER Graph
    Print a visual graph of saved points with branching and merging shown in ASCII, rather than returning structured objects.

    .EXAMPLE
    Show-History

    .EXAMPLE
    Show-History -Count 5

    .EXAMPLE
    Show-History -Graph -Count 30

    .NOTES
    A saved point in the history may still be local only if your active working area is ahead of the published version. Use Save-Work without -NoPush to publish, or check Find-CodeChange and Show-Remote to see the state.

    Steps:
    1. If -Graph is set, run a visual graph of saved points and print the lines directly to the host, then return.
    2. Load the most recent saved points up to the requested count.
    3. If none are found, return a single "no saved points" result object.
    4. Otherwise, return the array of saved-point objects.

    .LINK
    Save-Work

    .LINK
    Find-CodeChange

    .LINK
    Show-Remote

    .LINK
    Search-History
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [ValidateRange(1, 200)]
        [int]$Count = 20,

        [switch]$Graph
    )

    if ($Graph) {
        $root = Get-GERepoRoot
        $r = Invoke-GEGit -ArgumentList @('log', '--oneline', '--graph', '--decorate', "-n$Count") -WorkingDirectory $root -AllowFailure
        foreach ($line in $r.Output) {
            Write-Host $line
        }
        return
    }

    $history = @(Get-GEHistory -Count $Count)

    if ($history.Count -eq 0) {
        return [PSCustomObject]@{
            Repository = Get-GERepoRoot
            Message    = 'No saved points found.'
        }
    }

    return $history
}
