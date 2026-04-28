# Public-Set-Vault

## Summary

Source file: `Public\Set-Vault.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Public |
| Source file | `Public\Set-Vault.ps1` |
| File name | `Set-Vault.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Set-Vault | 1 | 20 | Helper |

## Source

```powershell
function Set-Vault {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('manager', 'manager-core', 'wincred', 'cache')]
        [string]$Helper = 'manager'
    )

    Test-GEGitInstalled | Out-Null

    if (-not $PSCmdlet.ShouldProcess('global Git config', "Set credential.helper to $Helper")) {
        return
    }

    Invoke-GEGit -ArgumentList @('config', '--global', 'credential.helper', $Helper) | Out-Null

    [PSCustomObject]@{
        CredentialHelper = $Helper
        Message          = "Git credential helper set to $Helper."
    }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
