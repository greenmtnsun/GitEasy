@{
    RootModule        = 'GitEasy.psm1'
    ModuleVersion     = '1.0.1.1'
    GUID              = '2e113abf-c0e7-4dfb-9cb1-69476d7541f6'
    Author            = 'Keith Ramsey'
    CompanyName       = 'Internal'
    Copyright         = ''
    Description       = 'GitEasy workflow for SQL, modules, and customer ecosystems.'
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
            ReleaseNotes = 'Fixed parser issues and added simple GitLab login helper functions and example scripts.'
        }
    }
}
