# GitEasy Quickstart

## Goal

GitEasy keeps Git commands friendly while the private engine does the
careful checks. Use GitEasy from inside a Git repository.

If you have not installed GitEasy yet, see [section 3 of the full
how-to](HOW-TO-USE-GITEASY.md#3-install-giteasy) — the 30-second
recipe drops it on your `$env:PSModulePath` so `Import-Module GitEasy`
works without a path.

## First thing every time

Run the state check example first:

```powershell
Import-Module GitEasy
$gee = (Get-Module GitEasy).ModuleBase
& "$gee\Examples\00-State-Check.ps1"
```

That tells you whether the module imports, whether Git sees a
repository, whether the working tree is clean, and whether the remote
is configured.

## Daily workflow

```powershell
Import-Module GitEasy
Find-CodeChange
Save-Work "describe what changed" -NoPush
Show-History -Count 5
```

Use `-NoPush` when you only want a local checkpoint.

Use normal push only after `Test-Login` passes.

## Check GitHub access

```powershell
Import-Module GitEasy
Get-VaultStatus
Show-Remote
Test-Login
```

Expected good result:

```text
Passed  : True
Message : Remote login/connectivity test passed.
```

## Configure GitHub HTTPS remote

```powershell
Set-Token -RemoteUrl "https://github.com/greenmtnsun/GitEasy.git"
Test-Login
```

Do not put a token in the URL. Git Credential Manager should handle
credentials.

## Save safely

Local only:

```powershell
Save-Work "local checkpoint" -NoPush
```

First push for a branch:

```powershell
Save-Work "first remote checkpoint" -SetUpstream
```

Normal save after upstream exists:

```powershell
Save-Work "updated docs"
```

## Commands currently implemented

- Save-Work
- Test-Login
- Set-Token
- Set-Ssh
- Set-Vault
- Get-VaultStatus
- Reset-Login
- Show-Remote
- Show-History
- Find-CodeChange
- New-WorkBranch
- Switch-Work
- Undo-Changes
- Restore-File
- Clear-Junk
- Show-Diagnostic
- Show-Change
- Search-History
- New-Release
- Show-Releases
- Get-Updates
