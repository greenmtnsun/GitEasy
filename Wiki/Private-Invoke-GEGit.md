# Private-Invoke-GEGit

## Summary

Source file: `Private\Invoke-GEGit.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Private |
| Source file | `Private\Invoke-GEGit.ps1` |
| File name | `Invoke-GEGit.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Invoke-GEGit | 1 | 25 | ArgumentList, WorkingDirectory, AllowFailure |

## Source

```powershell
function Invoke-GEGit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]]$ArgumentList,
        [string]$WorkingDirectory = (Get-Location).Path,
        [switch]$AllowFailure
    )
    $old = Get-Location
    try {
        Set-Location -LiteralPath $WorkingDirectory
        $oldNativePreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = & git @ArgumentList 2>&1
        $code = $LASTEXITCODE
        $ErrorActionPreference = $oldNativePreference
    }
    finally {
        $ErrorActionPreference = 'Stop'
        Set-Location -LiteralPath $old
    }
    if (($code -ne 0) -and (-not $AllowFailure)) {
        throw "Git failed: git $($ArgumentList -join ' ')`n$($output -join [Environment]::NewLine)"
    }
    [PSCustomObject]@{ ExitCode = $code; Output = @($output) }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
