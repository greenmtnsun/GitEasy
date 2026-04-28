# Public-Get-VaultStatus

## Summary

Source file: `Public\Get-VaultStatus.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Public |
| Source file | `Public\Get-VaultStatus.ps1` |
| File name | `Get-VaultStatus.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Get-VaultStatus | 1 | 13 |  |

## Source

```powershell
function Get-VaultStatus {
    [CmdletBinding()]
    param()

    Test-GEGitInstalled | Out-Null
    $helper = Invoke-GEGit -ArgumentList @('config', '--global', '--get', 'credential.helper') -AllowFailure
    $value = $helper.Output | Select-Object -First 1

    [PSCustomObject]@{
        CredentialHelper = $value
        Configured       = ($helper.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($value))
    }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
