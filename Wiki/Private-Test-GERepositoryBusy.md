# Private-Test-GERepositoryBusy

## Summary

Source file: `Private\Test-GERepositoryBusy.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Test-GERepositoryBusy.ps1` |
| File name | `Test-GERepositoryBusy.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Test-GERepositoryBusy | 1 | 25 | Path |

## Source

```powershell
function Test-GERepositoryBusy {
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)
    $root = Get-GERepoRoot -Path $Path
    $gitDirResult = Invoke-GEGit -ArgumentList @('rev-parse', '--git-dir') -WorkingDirectory $root
    $gitDir = $gitDirResult.Output | Select-Object -First 1
    if (-not [System.IO.Path]::IsPathRooted($gitDir)) {
        $gitDir = Join-Path $root $gitDir
    }
    $checks = @(
        @{ Name = 'merge'; Path = 'MERGE_HEAD' }
        @{ Name = 'cherry-pick'; Path = 'CHERRY_PICK_HEAD' }
        @{ Name = 'revert'; Path = 'REVERT_HEAD' }
        @{ Name = 'bisect'; Path = 'BISECT_START' }
        @{ Name = 'rebase'; Path = 'rebase-merge' }
        @{ Name = 'rebase'; Path = 'rebase-apply' }
    )
    $found = @()
    foreach ($check in $checks) {
        if (Test-Path -LiteralPath (Join-Path $gitDir $check.Path)) {
            $found += $check.Name
        }
    }
    [PSCustomObject]@{ IsBusy = ($found.Count -gt 0); Operations = @($found | Select-Object -Unique) }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
