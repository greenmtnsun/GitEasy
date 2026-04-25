function Get-GEConflictFiles {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    $root = Get-GERepoRoot -Path $Path
    $r = Invoke-GEGit -ArgumentList @('diff', '--name-only', '--diff-filter=U') -WorkingDirectory $root -AllowFailure
    @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}
