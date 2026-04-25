function Get-GEBranchName {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    $root = Get-GERepoRoot -Path $Path
    $r = Invoke-GEGit -ArgumentList @('branch', '--show-current') -WorkingDirectory $root -AllowFailure
    $branch = $r.Output | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($branch)) {
        $r = Invoke-GEGit -ArgumentList @('symbolic-ref', '--short', 'HEAD') -WorkingDirectory $root -AllowFailure
        $branch = $r.Output | Select-Object -First 1
    }
    if ([string]::IsNullOrWhiteSpace($branch)) {
        throw 'Unable to determine current branch. Repository may be detached or corrupt.'
    }
    $branch
}
