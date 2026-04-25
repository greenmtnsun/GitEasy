function Get-GERepoRoot {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    Test-GEGitInstalled | Out-Null
    $r = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -WorkingDirectory $Path
    $root = $r.Output | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($root)) { throw 'Not inside a Git repository.' }
    $root
}
