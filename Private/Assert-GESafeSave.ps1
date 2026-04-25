function Assert-GESafeSave {
    [CmdletBinding()]
    param([switch]$NoPush, [switch]$SetUpstream)
    $root = Get-GERepoRoot
    $branch = Get-GEBranchName -Path $root
    $status = Get-GEStatus -Path $root
    $upstream = Get-GEUpstreamBranch -Path $root
    if ((-not $NoPush) -and [string]::IsNullOrWhiteSpace($upstream) -and (-not $SetUpstream)) {
        throw 'No upstream branch. Use Save-Work -SetUpstream or Save-Work -NoPush.'
    }
    [PSCustomObject]@{ Root = $root; Branch = $branch; Status = $status; Upstream = $upstream }
}
