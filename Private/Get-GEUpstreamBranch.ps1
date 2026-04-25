function Get-GEUpstreamBranch {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    $root = Get-GERepoRoot -Path $Path
    $r = Invoke-GEGit -ArgumentList @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}') -WorkingDirectory $root -AllowFailure
    if ($r.ExitCode -ne 0) { return $null }
    $r.Output | Select-Object -First 1
}
