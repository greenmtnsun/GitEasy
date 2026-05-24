BeforeAll {
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ModulePath  = Join-Path $ProjectRoot 'GitEasy.psd1'

# Publish-readiness contract. Every It in this file represents one row of
# the docs/PSGALLERY-METADATA-PLAYBOOK.md pre-publish checklist. If any of
# these fail, do NOT run Publish-Module. Fix the gap first.
#
# These tests verify metadata SHAPE (values, presence, formats). They do
# NOT touch the network. URL reachability is checked by
# tools/Publish-GitEasy.ps1 at stage time so that:
#   - Tests stay deterministic in CI / on air-gapped machines.
#   - Network checks happen close to the actual publish.
}

Describe 'GitEasy publish readiness - core manifest fields' {
    BeforeAll {
        $script:manifest = Import-PowerShellDataFile -LiteralPath $ModulePath
        Test-ModuleManifest -Path $ModulePath -ErrorAction Stop | Out-Null
    }

    It 'GUID is the canonical GitEasy GUID' {
        $manifest.GUID | Should -Be '2e113abf-c0e7-4dfb-9cb1-69476d7541f6'
    }

    It 'ModuleVersion is three-segment SemVer' {
        $manifest.ModuleVersion | Should -Match '^\d+\.\d+\.\d+$'
    }

    It 'Author is set' {
        [string]::IsNullOrWhiteSpace($manifest.Author) | Should -Be $false
    }

    It 'CompanyName is set' {
        [string]::IsNullOrWhiteSpace($manifest.CompanyName) | Should -Be $false
    }

    It 'Copyright contains a four-digit year' {
        $manifest.Copyright | Should -Match '20\d\d'
    }

    It 'Copyright references the SPDX license id' {
        $manifest.Copyright | Should -Match 'MPL'
    }

    It 'Description is non-empty' {
        [string]::IsNullOrWhiteSpace($manifest.Description) | Should -Be $false
    }

    It 'Description is at most 400 characters (avoid search-card truncation)' {
        ($manifest.Description.Length -le 400) | Should -Be $true
    }

    It 'Description is at least 80 characters (avoid telegraphic blurb)' {
        ($manifest.Description.Length -ge 80) | Should -Be $true
    }

    It 'Description names the audience' {
        $manifest.Description | Should -Match '(?i)sysadmin|compliance|change manager'
    }

    It 'Description names at least one exported command' {
        $manifest.Description | Should -Match '(Save-Work|Find-CodeChange|Show-History|Set-Token|Test-Login)'
    }

    It 'PowerShellVersion is 5.1' {
        $manifest.PowerShellVersion | Should -Be '5.1'
    }

    It 'CompatiblePSEditions includes Desktop' {
        ($manifest.CompatiblePSEditions -contains 'Desktop') | Should -Be $true
    }

    It 'CompatiblePSEditions includes Core' {
        ($manifest.CompatiblePSEditions -contains 'Core') | Should -Be $true
    }

    It 'FormatsToProcess files all exist on disk' {
        foreach ($f in $manifest.FormatsToProcess) {
            Test-Path (Join-Path $ProjectRoot $f) | Should -Be $true
        }
    }
}

Describe 'GitEasy publish readiness - exports' {
    BeforeAll {
        $script:manifest = Import-PowerShellDataFile -LiteralPath $ModulePath
    }

    It 'CmdletsToExport is an empty array, not a wildcard' {
        ($manifest.CmdletsToExport.Count -eq 0) | Should -Be $true
    }

    It 'VariablesToExport is an empty array, not a wildcard' {
        ($manifest.VariablesToExport.Count -eq 0) | Should -Be $true
    }

    It 'AliasesToExport contains the three documented singular-form aliases' {
        # Plural cmdlet names are a brand choice (see site/who.html#naming);
        # singular aliases are exported so PowerShell convention-followers
        # can also type Get-Update / Show-Release / Undo-Change.
        $expected = @('Get-Update', 'Show-Release', 'Undo-Change') | Sort-Object
        $actual   = @($manifest.AliasesToExport | Sort-Object)
        ($actual -join '|') | Should -Be ($expected -join '|')
    }

    It 'AliasesToExport contains no wildcards' {
        ($manifest.AliasesToExport -join ',') | Should -Not -Match '\*'
    }

    It 'FunctionsToExport contains no wildcards' {
        ($manifest.FunctionsToExport -join ',') | Should -Not -Match '\*'
    }

    It 'FunctionsToExport matches the Public\ directory exactly' {
        $publicFiles = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'Public') -Filter '*.ps1' |
                        ForEach-Object { $_.BaseName } | Sort-Object)
        $exported = @($manifest.FunctionsToExport | Sort-Object)
        ($publicFiles -join '|') | Should -Be ($exported -join '|')
    }
}

Describe 'GitEasy publish readiness - PSData' {
    BeforeAll {
        $script:manifest = Import-PowerShellDataFile -LiteralPath $ModulePath
        $script:psdata   = $manifest.PrivateData.PSData
    }

    It 'Tags has 10 or more entries' {
        ($psdata.Tags.Count -ge 10) | Should -Be $true
    }

    It 'Tags includes Git' {
        ($psdata.Tags -contains 'Git') | Should -Be $true
    }

    It 'Tags includes PSEdition_Desktop (drives Find-Module -Tag)' {
        ($psdata.Tags -contains 'PSEdition_Desktop') | Should -Be $true
    }

    It 'Tags includes PSEdition_Core (drives Find-Module -Tag)' {
        ($psdata.Tags -contains 'PSEdition_Core') | Should -Be $true
    }

    It 'Tags does not include a generic "PowerShell" tag (every module is PowerShell)' {
        foreach ($t in $psdata.Tags) {
            ($t.ToLower() -eq 'powershell') | Should -Be $false
        }
    }

    It 'No tag contains whitespace' {
        foreach ($t in $psdata.Tags) {
            $t | Should -Not -Match '\s'
        }
    }

    It 'LicenseUri is HTTPS' {
        $psdata.LicenseUri | Should -Match '^https://'
    }

    It 'LicenseUri points at the in-repo LICENSE file (display matches shipped license)' {
        $psdata.LicenseUri | Should -Match 'github\.com/greenmtnsun/GitEasy/blob/main/LICENSE'
    }

    It 'ProjectUri is HTTPS' {
        $psdata.ProjectUri | Should -Match '^https://'
    }

    It 'ProjectUri is the canonical GitHub repo' {
        $psdata.ProjectUri | Should -Be 'https://github.com/greenmtnsun/GitEasy'
    }

    It 'IconUri is set' {
        [string]::IsNullOrWhiteSpace($psdata.IconUri) | Should -Be $false
    }

    It 'IconUri is on raw.githubusercontent.com (direct image, not a webpage)' {
        $psdata.IconUri | Should -Match '^https://raw\.githubusercontent\.com/'
    }

    It 'IconUri references a .png file' {
        $psdata.IconUri | Should -Match '\.png$'
    }

    It 'ReleaseNotes is inline content, not just a URL stub' {
        ($psdata.ReleaseNotes.Length -gt 100) | Should -Be $true
    }

    It 'ReleaseNotes spans multiple lines (Gallery renders plaintext, line breaks matter)' {
        $psdata.ReleaseNotes | Should -Match "`n"
    }

    It 'ReleaseNotes references the current ModuleVersion' {
        $psdata.ReleaseNotes | Should -Match ([regex]::Escape($manifest.ModuleVersion))
    }

    It 'Prerelease is unset for a stable release' {
        $val = $psdata['Prerelease']
        ($null -eq $val -or [string]::IsNullOrWhiteSpace($val)) | Should -Be $true
    }

    It 'RequireLicenseAcceptance is unset (MPL-2.0 does not need click-through)' {
        $val = $psdata['RequireLicenseAcceptance']
        ($null -eq $val -or $val -eq $false) | Should -Be $true
    }
}

Describe 'GitEasy publish readiness - repo files the Gallery surface depends on' {
    BeforeAll {
        $script:manifest = Import-PowerShellDataFile -LiteralPath $ModulePath
    }

    It 'LICENSE file exists at repo root' {
        Test-Path (Join-Path $ProjectRoot 'LICENSE') | Should -Be $true
    }

    It 'LICENSE file references Mozilla Public License Version 2.0' {
        $licText = Get-Content -LiteralPath (Join-Path $ProjectRoot 'LICENSE') -Raw
        $licText | Should -Match 'Mozilla Public License Version 2\.0'
    }

    It 'README.md exists at repo root' {
        Test-Path (Join-Path $ProjectRoot 'README.md') | Should -Be $true
    }

    It 'CHANGELOG.md exists at repo root' {
        Test-Path (Join-Path $ProjectRoot 'CHANGELOG.md') | Should -Be $true
    }

    It 'CHANGELOG.md contains an entry for the current ModuleVersion' {
        $changelog = Get-Content -LiteralPath (Join-Path $ProjectRoot 'CHANGELOG.md') -Raw
        $changelog | Should -Match ([regex]::Escape($manifest.ModuleVersion))
    }
}

Describe 'GitEasy publish readiness - publish tooling' {
    It 'tools/Publish-GitEasy.ps1 exists' {
        Test-Path (Join-Path $ProjectRoot 'tools\Publish-GitEasy.ps1') | Should -Be $true
    }

    It 'tools/Publish-GitEasy.ps1 parses without errors' {
        $f = Join-Path $ProjectRoot 'tools\Publish-GitEasy.ps1'
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$parseErrors) | Out-Null
        @($parseErrors).Count | Should -Be 0
    }

    It 'tools/Publish-GitEasy.ps1 has a [CmdletBinding()] block' {
        $content = Get-Content -LiteralPath (Join-Path $ProjectRoot 'tools\Publish-GitEasy.ps1') -Raw
        $content | Should -Match '\[CmdletBinding\(\)\]'
    }

    It 'tools/Publish-GitEasy.ps1 gates real publish behind both -Publish and -NuGetApiKey' {
        $content = Get-Content -LiteralPath (Join-Path $ProjectRoot 'tools\Publish-GitEasy.ps1') -Raw
        $content | Should -Match '-Publish'
        $content | Should -Match '-NuGetApiKey'
    }
}
