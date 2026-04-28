# Private-Get-GEBranchName

## Summary

Source file: `Private\Get-GEBranchName.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Get-GEBranchName.ps1` |
| File name | `Get-GEBranchName.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-GEBranchName | 1 | 15 | Path |

## Source

```powershell
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

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
