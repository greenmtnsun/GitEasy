function Get-GEStatus {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    $root = Get-GERepoRoot -Path $Path
    $r = Invoke-GEGit -ArgumentList @('status', '--porcelain=v1') -WorkingDirectory $root
    $lines = @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    [PSCustomObject]@{ Root = $root; Lines = $lines; IsClean = ($lines.Count -eq 0); Count = $lines.Count }
}
