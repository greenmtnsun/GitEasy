# GitEasy V2 Quickstart

## Goal

GitEasy keeps Git commands friendly while the private engine does the careful checks.

Use GitEasy from inside a Git repository.

Current working project:

```powershell
C:\Sysadmin\Scripts\GitEasyV2
```

## First thing every time

Run the state check example first:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Sysadmin\Scripts\GitEasyV2\Examples\00-State-Check.ps1
```

That tells you whether the module imports, whether Git sees a repository, whether the working tree is clean, and whether the remote is configured.

## Daily workflow

```powershell
Set-Location C:\Sysadmin\Scripts\GitEasyV2
Import-Module C:\Sysadmin\Scripts\GitEasyV2\GitEasy.psd1 -Force
Find-CodeChange
Save-Work "describe what changed" -NoPush
Show-History -Count 5
```

Use `-NoPush` when you only want a local checkpoint.

Use normal push only after `Test-Login` passes.

## Check GitHub access

```powershell
Set-Location C:\Sysadmin\Scripts\GitEasyV2
Import-Module C:\Sysadmin\Scripts\GitEasyV2\GitEasy.psd1 -Force
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

Do not put a token in the URL. Git Credential Manager should handle credentials.

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

## Commands still intentionally stubbed

- New-WorkBranch
- Switch-Work
- Undo-Changes
- Restore-File
- Clear-Junk
