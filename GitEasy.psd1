@{
    RootModule        = 'GitEasy.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a7f52f47-87b2-42c4-9f37-9f329edb7a01'
    Author            = 'Keith Ramsey'
    CompanyName       = 'Keith Ramsey'
    Copyright         = '(c) Keith Ramsey. Licensed under the Mozilla Public License 2.0.'
    Description       = 'Plain-English Git workflow for PowerShell. Classic GitEasy public commands with a safer V2 engine, per-invocation diagnostic logs, and no jargon in the user surface.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Clear-Junk'
        'Find-CodeChange'
        'Get-VaultStatus'
        'New-WorkBranch'
        'Reset-Login'
        'Restore-File'
        'Save-Work'
        'Set-Ssh'
        'Set-Token'
        'Set-Vault'
        'Show-Diagnostic'
        'Show-History'
        'Show-Remote'
        'Switch-Work'
        'Test-Login'
        'Undo-Changes'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('git', 'github', 'gitlab', 'sysadmin', 'plain-english', 'beginner-friendly', 'powershell', 'workflow')
            LicenseUri   = 'https://www.mozilla.org/MPL/2.0/'
            ProjectUri   = 'https://github.com/greenmtnsun/GitEasy'
            ReleaseNotes = 'See https://github.com/greenmtnsun/GitEasy/blob/main/CHANGELOG.md'
        }
    }
}
