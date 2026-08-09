@{
    RootModule           = 'GitEasy.psm1'
    ModuleVersion        = '1.5.6'
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
GitEasy 1.5.6 - 2026-08-09
==========================

Save-Work now takes an optional -Files parameter for selective staging:
pass one or more paths to commit only those files instead of everything.
The default is unchanged (stage all), so existing usage is unaffected.

Also: comment-based help now carries a numbered Steps: blueprint in every
function. Documentation only, no behavior change.

Full notes:
https://github.com/greenmtnsun/GitEasy/blob/main/CHANGELOG.md
'@
        }
    }
}
