# Private-Get-GEUpstreamBranch

## Summary

Source file: `Private\Get-GEUpstreamBranch.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Get-GEUpstreamBranch.ps1` |
| File name | `Get-GEUpstreamBranch.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-GEUpstreamBranch | 1 | 8 | Path |

## Source

```powershell
function Get-GEUpstreamBranch {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    $root = Get-GERepoRoot -Path $Path
    $r = Invoke-GEGit -ArgumentList @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}') -WorkingDirectory $root -AllowFailure
    if ($r.ExitCode -ne 0) { return $null }
    $r.Output | Select-Object -First 1
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
