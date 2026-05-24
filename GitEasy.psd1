@{
    RootModule           = 'GitEasy.psm1'
    ModuleVersion        = '1.5.3'
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
                'Plain-English'
                'Beginner-Friendly'
                'PSEdition_Desktop'
                'PSEdition_Core'
            )
            LicenseUri   = 'https://github.com/greenmtnsun/GitEasy/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/greenmtnsun/GitEasy'
            IconUri      = 'https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/Assets/icon.png'
            ReleaseNotes = @'
GitEasy 1.5.3 - 2026-05-21
==========================

PowerShell Gallery readiness release. No public-command behavior
change, no private-helper signature change, no format.ps1xml change.
554 tests on Pester 5.7.1, PS 5.1 + PS 7. (16 tests for private tooling live in GitEasy-internal.)

Gallery metadata
----------------
- Description rewritten audience-first (sysadmins / change managers /
  compliance teams), under 400 chars to avoid search-card truncation.
- Tags replaced with a 14-entry list incl. PSEdition_Desktop and
  PSEdition_Core (drive Find-Module -Tag), DevOps, Automation,
  SourceControl, VersionControl, Bitbucket.
- CompatiblePSEditions = @('Desktop','Core') stamped explicitly.
- IconUri set; LicenseUri now points at the in-repo LICENSE file
  (display matches shipped license).
- ReleaseNotes is now inline plaintext. PSGallery does not render
  Markdown; a URL stub wastes the surface.

Tooling
-------
- tools/Publish-GitEasy.ps1 - enumerate-then-include staging,
  manifest revalidation, Pester gate, URI reachability check,
  dry-run by default. Real publish requires -Publish + -NuGetApiKey.
- Tests/GitEasy.PublishReadiness.Tests.ps1 - 47 tests verifying
  every Gallery-surface field (one per playbook checklist row).

Docs
----
- docs/FOR-GIT-EXPERTS.md - dedicated expert-audience reference
  covering the underlying git call sequence, scrub rules,
  return-object schema, scripting patterns, override knobs, and
  where to fall back to raw Git.
- docs/PSGALLERY-METADATA-PLAYBOOK.md - pre-publish reference for
  every Gallery-surfaced metadata field.
- README + HOW-TO install recipes drop GitEasy into the user-scope
  PowerShell module folder so Import-Module GitEasy works without a
  path. The previous C:\Sysadmin\Scripts install path was a leftover
  from the author's local development folder and was never the right
  default to publish.

Full notes:
https://github.com/greenmtnsun/GitEasy/blob/main/CHANGELOG.md
'@
        }
    }
}
