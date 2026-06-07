@{
    RootModule           = 'GitEasy.psm1'
    ModuleVersion        = '1.6.0'
    GUID                 = '2e113abf-c0e7-4dfb-9cb1-69476d7541f6'
    Author               = 'Keith Ramsey'
    CompanyName          = 'Keith Ramsey'
    Copyright            = '(c) 2026 Keith Ramsey. Licensed under MPL-2.0.'
    Description          = 'Save your work without learning Git. Plain-English PowerShell commands for sysadmins, change managers, DBAs, compliance teams, and 25 other non-developer roles — no jargon, no raw Git output. Save-Work, Find-CodeChange, Show-History, Test-Login. Credentials scrubbed before anything hits disk. PS 5.1 and 7. MPL-2.0.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FormatsToProcess     = @('Format\GitEasy.format.ps1xml')
    FunctionsToExport    = @(
        'Clear-Junk'
        'Disable-GitEasy'
        'Enable-GitEasy'
        'Find-CodeChange'
        'Get-Updates'
        'Get-VaultStatus'
        'New-BugReport'
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
    AliasesToExport      = @(
        'Get-Update'
        'Show-Release'
        'Undo-Change'
    )
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
                'PlainEnglish'
                'BeginnerFriendly'
                'Windows'
                'PSEdition_Desktop'
                'PSEdition_Core'
            )
            LicenseUri   = 'https://github.com/greenmtnsun/GitEasy/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/greenmtnsun/GitEasy'
            IconUri      = 'https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/Assets/icon.png'
            ReleaseNotes = @'
GitEasy 1.6.0 - 2026-06-07
==========================

Three new commands so GitEasy can be your everyday Git front door.

Enable-GitEasy / Disable-GitEasy: make GitEasy load automatically in every
PowerShell session by adding (or removing) a clearly marked block in your
personal startup file. Safe to run repeatedly; fully reversible.

New-BugReport: opens a pre-filled GitHub issue in your browser with a setup
snapshot and a credential-scrubbed excerpt of your most recent diagnostic
log. Nothing is sent on its own - you review and submit.

Full notes:
https://github.com/greenmtnsun/GitEasy/blob/main/CHANGELOG.md
'@
        }
    }
}
