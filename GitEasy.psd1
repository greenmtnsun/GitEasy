@{
    RootModule           = 'GitEasy.psm1'
    ModuleVersion        = '1.5.2'
    GUID                 = '2e113abf-c0e7-4dfb-9cb1-69476d7541f6'
    Author               = 'Keith Ramsey'
    CompanyName          = 'Keith Ramsey'
    Copyright            = '(c) 2026 Keith Ramsey. Licensed under MPL-2.0.'
    Description          = 'Plain-English Git for sysadmins, change managers, and compliance teams. Five everyday PowerShell commands (Save-Work, Find-CodeChange, Show-History, Set-Token, Test-Login) wrap git on Windows with no raw output, no jargon, and one log file per command. PowerShell 5.1 and 7. MPL-2.0.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FormatsToProcess     = @('Format\GitEasy.format.ps1xml')
    FunctionsToExport    = @(
        'Clear-Junk'
        'Find-CodeChange'
        'Get-Updates'
        'Get-VaultStatus'
        'New-Release'
        'New-WorkBranch'
        'Reset-Login'
        'Restore-File'
        'Save-Work'
        'Search-History'
        'Set-Ssh'
        'Set-Token'
        'Set-Vault'
        'Show-Change'
        'Show-Diagnostic'
        'Show-History'
        'Show-Releases'
        'Show-Remote'
        'Switch-Work'
        'Test-Login'
        'Undo-Changes'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @(
                'Git'
                'GitHub'
                'GitLab'
                'Bitbucket'
                'SourceControl'
                'VersionControl'
                'Sysadmin'
                'DevOps'
                'Automation'
                'Workflow'
                'Plain-English'
                'Beginner-Friendly'
                'PSEdition_Desktop'
                'PSEdition_Core'
            )
            LicenseUri   = 'https://github.com/greenmtnsun/GitEasy/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/greenmtnsun/GitEasy'
            IconUri      = 'https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/Assets/icon.png'
            ReleaseNotes = @'
GitEasy 1.5.2 - 2026-05-20
==========================

Second adversarial pass after the 2026-05-17 credential-surface review.
522 tests on Pester 3.4.0, PS 5.1 + PS 7.

Security (CWE-200 / CWE-532)
----------------------------
- F-04 (High) - Set-Ssh HTTPS->SSH conversion no longer persists
  credential-embedded user-info from .git/config. Convert-GERemoteToSsh
  now parses with [uri] and refuses non-empty UserInfo.
- F-05 (Medium) - Test-Login return object and error message now route
  through Format-GESafeUrl. Format-GESafeUrl generalised to sanitise
  URLs that appear mid-string.
- F-06 (Medium) - Invoke-GEGit step header and thrown error no longer
  echo credential-bearing arguments. Every argument runs through
  Format-GESafeUrl (no-op on non-URL args) before being joined.

Correctness
-----------
- Reset-Login cmdkey path now checks each cmdkey exit code before
  flipping clearedSomething.
- Save-Work ModuleVersion regex now accepts single- or double-quoted
  version values.
- Set-Vault now opens a log session, returns a structured object on
  every path including -WhatIf.

Plain-English / no-jargon
-------------------------
- Show-Change comment-based help describes the -NextSave parameter
  (1.5.0 rename from -Staged left CBH stale).
- Search-History return property Hash renamed to Id.
- Format/GitEasy.format.ps1xml column labels Staged -> Ready,
  Unstaged -> Pending, Untracked -> New. Property names preserved.

Cross-platform
--------------
- Show-Diagnostic platform-detects before Start-Process explorer.exe
  / Start-Process $logFile. Non-Windows hosts get a path hint.

Full notes and trust-boundary trace:
https://github.com/greenmtnsun/GitEasy/blob/main/CHANGELOG.md
https://github.com/greenmtnsun/GitEasy/blob/main/docs/SECURITY-FINDINGS-2026-05-20.md
'@
        }
    }
}
