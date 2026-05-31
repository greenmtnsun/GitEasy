@{
    RootModule           = 'GitEasy.psm1'
    ModuleVersion        = '1.5.5'
    GUID                 = '2e113abf-c0e7-4dfb-9cb1-69476d7541f6'
    Author               = 'Keith Ramsey'
    CompanyName          = 'Keith Ramsey'
    Copyright            = '(c) 2026 Keith Ramsey. Licensed under MPL-2.0.'
    Description          = @'
Save your work without learning Git. GitEasy gives sysadmins, change managers, DBAs, compliance teams, and 25 other non-developer roles a set of plain-English PowerShell commands that wrap git — with no jargon, no raw output, no way to accidentally overwrite someone else's work.

If you've ever closed PowerShell because the Git error message felt scarier than the change you were trying to save, this is for you.

Five commands cover most days: Save-Work, Find-CodeChange, Show-History, Show-Remote, Test-Login. There's more when you're ready — and I've kept it just as plain. Check the HOW-TO doc included in this package. Give it a try — the worst that happens is you type Get-Help Save-Work.

Every command logs what it did. Credentials are scrubbed before anything hits disk. PowerShell 5.1 and 7. MPL-2.0.
'@
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
                'PowerShell'
                'PSEdition_Desktop'
                'PSEdition_Core'
            )
            LicenseUri   = 'https://github.com/greenmtnsun/GitEasy/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/greenmtnsun/GitEasy'
            IconUri      = 'https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/Assets/icon.png'
            ReleaseNotes = @'
GitEasy 1.5.5 - 2026-05-31
==========================

PSGallery tag corrections + GitHub Actions CI. No functional change.

Tags: Plain-English -> PlainEnglish, Beginner-Friendly -> BeginnerFriendly
(hyphenated tags are single tokens in PSGallery search). Added Windows and
PowerShell as top search terms the module was missing.

CI: GitHub Actions now runs the full Pester suite (PS 7 + PS 5.1) and
PSScriptAnalyzer on every push and PR.

Full notes:
https://github.com/greenmtnsun/GitEasy/blob/main/CHANGELOG.md
'@
        }
    }
}
