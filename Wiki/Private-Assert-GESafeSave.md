# Private-Assert-GESafeSave

## Summary

Source file: `Private\Assert-GESafeSave.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Assert-GESafeSave.ps1` |
| File name | `Assert-GESafeSave.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Assert-GESafeSave | 1 | 23 |  |

## Source

```powershell
function Assert-GESafeSave {
    [CmdletBinding()]
    param()

    $RepositoryRoot = git rev-parse --show-toplevel 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepositoryRoot)) {
        throw 'Not currently inside a Git repository.'
    }

    $UnmergedFiles = @(git diff --name-only --diff-filter=U 2>$null)

    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to check for unresolved merge conflicts.'
    }

    if ($UnmergedFiles.Count -gt 0) {
        $Message = 'Unresolved merge conflicts found. Fix these files before Save-Work: ' + ($UnmergedFiles -join ', ')
        throw $Message
    }

    return $true
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
