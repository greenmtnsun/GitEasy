# Private-Get-GERepoRoot

## Summary

Source file: `Private\Get-GERepoRoot.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Get-GERepoRoot.ps1` |
| File name | `Get-GERepoRoot.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-GERepoRoot | 1 | 9 | Path |

## Source

```powershell
function Get-GERepoRoot {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    Test-GEGitInstalled | Out-Null
    $r = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -WorkingDirectory $Path
    $root = $r.Output | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($root)) { throw 'Not inside a Git repository.' }
    $root
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
