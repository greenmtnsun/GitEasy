# GitEasy V2 Command Examples

## Import the module

```powershell
Set-Location C:\Sysadmin\Scripts\GitEasy
Import-Module C:\Sysadmin\Scripts\GitEasy\GitEasy.psd1 -Force
Get-Command -Module GitEasy
```

## See what changed

```powershell
Find-CodeChange
```

Use this before saving. It tells you if the tree is clean, dirty, staged, unstaged, or has untracked files.

## Save locally only

```powershell
Save-Work "add examples pack" -NoPush
```

This is the safest Save-Work mode.

## Check recent history

```powershell
Show-History -Count 5
```

## Show remote connection

```powershell
Show-Remote
```

## Check login or access

```powershell
Test-Login
```

If origin is missing, configure it with Set-Token.

## Set HTTPS remote

```powershell
Set-Token -RemoteUrl "https://github.com/greenmtnsun/GitEasy.git"
Test-Login
```

## Set credential helper

```powershell
Set-Vault -Helper manager
Get-VaultStatus
```

## Switch origin to SSH

```powershell
Set-Ssh
Show-Remote
Test-Login
```

Only use SSH if your SSH keys are configured.

## Reset bad HTTPS credential

```powershell
Reset-Login
Test-Login
```

This asks Git to reject the cached HTTPS credential so Git Credential Manager can prompt again.
