# Private-Test-GEGitInstalled

## Summary

Source file: `Private\Test-GEGitInstalled.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Test-GEGitInstalled.ps1` |
| File name | `Test-GEGitInstalled.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Test-GEGitInstalled | 1 | 8 |  |

## Source

```powershell
function Test-GEGitInstalled {
    [CmdletBinding()]
    param()
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git was not found in PATH.'
    }
    $true
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
