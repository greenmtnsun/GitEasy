$ProjectRoot = Split-Path -Parent $PSScriptRoot
$CommandWikiScript = Join-Path $ProjectRoot 'Update-GitEasyCommandWiki.ps1'
$PrivateWikiScript = Join-Path $ProjectRoot 'Update-GitEasyPrivateWiki.ps1'

function New-FakeModuleFixture {
    param(
        [Parameter(Mandatory)] [string]$Path
    )

    New-Item -Path (Join-Path $Path 'Public')  -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path $Path 'Private') -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path $Path 'Tests')   -ItemType Directory -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $Path 'GitEasy.psd1') -Encoding UTF8 -Value @"
@{
    RootModule = 'GitEasy.psm1'
    ModuleVersion = '0.0.1'
    GUID = '00000000-0000-0000-0000-000000000001'
    Author = 'Pester'
    FunctionsToExport = @('Sample-Cmd')
}
"@

    Set-Content -LiteralPath (Join-Path $Path 'GitEasy.psm1') -Encoding UTF8 -Value @"
Set-StrictMode -Version Latest
Get-ChildItem -LiteralPath (Join-Path `$PSScriptRoot 'Private') -Filter '*.ps1' -File | ForEach-Object { . `$_.FullName }
Get-ChildItem -LiteralPath (Join-Path `$PSScriptRoot 'Public')  -Filter '*.ps1' -File | ForEach-Object { . `$_.FullName }
Export-ModuleMember -Function 'Sample-Cmd'
"@

    Set-Content -LiteralPath (Join-Path $Path 'Public\Sample-Cmd.ps1') -Encoding UTF8 -Value @"
function Sample-Cmd {
    <#
    .SYNOPSIS
    A sample command for testing.

    .DESCRIPTION
    Sample-Cmd is a fake command used by the wiki-script Pester tests.

    .PARAMETER Name
    A test parameter.

    .EXAMPLE
    Sample-Cmd -Name foo
    #>
    [CmdletBinding()]
    param([string]`$Name)
    `$Name
}
"@

    Set-Content -LiteralPath (Join-Path $Path 'Private\Get-GESample.ps1') -Encoding UTF8 -Value @"
function Get-GESample {
    [CmdletBinding()]
    param([string]`$Path)
    `$Path
}
"@
}

function New-EmptyWikiFixture {
    param(
        [Parameter(Mandatory)] [string]$Path
    )

    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path $Path '.git') -ItemType Directory -Force | Out-Null
}

Describe 'Update-GitEasyCommandWiki.ps1' {
    BeforeEach {
        $script:Stem      = [guid]::NewGuid().ToString('N').Substring(0, 8)
        $script:FakeRoot  = Join-Path ([System.IO.Path]::GetTempPath()) ("GE_WikiSrc_$script:Stem")
        $script:FakeWiki  = Join-Path ([System.IO.Path]::GetTempPath()) ("GE_WikiOut_$script:Stem")

        New-FakeModuleFixture -Path $script:FakeRoot
        New-EmptyWikiFixture  -Path $script:FakeWiki
    }

    AfterEach {
        Remove-Item -LiteralPath $script:FakeRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:FakeWiki -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'parses without errors' {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($CommandWikiScript, [ref]$tokens, [ref]$errors) | Out-Null
        @($errors).Count | Should Be 0
    }

    It 'creates a public-command page from CBH' {
        & $CommandWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null

        $page = Join-Path $script:FakeWiki 'Public-Sample-Cmd.md'
        Test-Path -LiteralPath $page | Should Be $true

        $body = Get-Content -LiteralPath $page -Raw
        $body | Should Match 'A sample command for testing.'
        $body | Should Match '## Summary'
        $body | Should Match '## Description'
        $body | Should Match '## Parameters'
        $body | Should Match '## Examples'
    }

    It 'embeds the source-hash watermark on each page' {
        & $CommandWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null

        $body = Get-Content -LiteralPath (Join-Path $script:FakeWiki 'Public-Sample-Cmd.md') -Raw
        $body | Should Match 'ge-source-sha256:'
    }

    It 'embeds the module-version watermark in the index' {
        & $CommandWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null

        $body = Get-Content -LiteralPath (Join-Path $script:FakeWiki 'Public-Commands.md') -Raw
        $body | Should Match 'ge-module-version:\s*0\.0\.1'
    }

    It '-DryRun writes no files' {
        & $CommandWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki -DryRun | Out-Null

        Test-Path -LiteralPath (Join-Path $script:FakeWiki 'Public-Sample-Cmd.md') | Should Be $false
    }

    It 'removes orphan pages whose source command no longer exists' {
        Set-Content -LiteralPath (Join-Path $script:FakeWiki 'Public-Stranger.md') -Encoding UTF8 -Value '# Stranger'

        & $CommandWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null

        Test-Path -LiteralPath (Join-Path $script:FakeWiki 'Public-Stranger.md') | Should Be $false
    }

    It 'is idempotent when run twice' {
        & $CommandWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null
        $first = (Get-Item -LiteralPath (Join-Path $script:FakeWiki 'Public-Sample-Cmd.md')).Length

        & $CommandWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null
        $second = (Get-Item -LiteralPath (Join-Path $script:FakeWiki 'Public-Sample-Cmd.md')).Length

        $second | Should Be $first
    }
}

Describe 'Update-GitEasyPrivateWiki.ps1' {
    BeforeEach {
        $script:Stem      = [guid]::NewGuid().ToString('N').Substring(0, 8)
        $script:FakeRoot  = Join-Path ([System.IO.Path]::GetTempPath()) ("GE_PrivSrc_$script:Stem")
        $script:FakeWiki  = Join-Path ([System.IO.Path]::GetTempPath()) ("GE_PrivOut_$script:Stem")

        New-FakeModuleFixture -Path $script:FakeRoot
        New-EmptyWikiFixture  -Path $script:FakeWiki
    }

    AfterEach {
        Remove-Item -LiteralPath $script:FakeRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:FakeWiki -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'parses without errors' {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($PrivateWikiScript, [ref]$tokens, [ref]$errors) | Out-Null
        @($errors).Count | Should Be 0
    }

    It 'creates a private helper page with the required sections' {
        & $PrivateWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null

        $page = Join-Path $script:FakeWiki 'Private-Get-GESample.md'
        Test-Path -LiteralPath $page | Should Be $true

        $body = Get-Content -LiteralPath $page -Raw
        $body | Should Match '## Summary'
        $body | Should Match '## Description'
        $body | Should Match '## Internal Usage'
        $body | Should Match '## Parameters'
        $body | Should Match '## Internal Examples'
        $body | Should Match '## Safety Notes'
        $body | Should Match '## Related Public Commands'
        $body | Should Match '## Source File'
        $body | Should Match '## Source'
        $body | Should Match '## Related Pages'
    }

    It 'creates a Private-Helpers index page' {
        & $PrivateWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null

        $index = Join-Path $script:FakeWiki 'Private-Helpers.md'
        Test-Path -LiteralPath $index | Should Be $true

        $body = Get-Content -LiteralPath $index -Raw
        $body | Should Match 'Get-GESample'
    }

    It 'removes orphan pages whose helper no longer exists' {
        Set-Content -LiteralPath (Join-Path $script:FakeWiki 'Private-Stranger.md') -Encoding UTF8 -Value '# Stranger'

        & $PrivateWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null

        Test-Path -LiteralPath (Join-Path $script:FakeWiki 'Private-Stranger.md') | Should Be $false
    }

    It 'is idempotent when run twice' {
        & $PrivateWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null
        $first = (Get-Item -LiteralPath (Join-Path $script:FakeWiki 'Private-Get-GESample.md')).Length

        & $PrivateWikiScript -ProjectRoot $script:FakeRoot -WikiRoot $script:FakeWiki | Out-Null
        $second = (Get-Item -LiteralPath (Join-Path $script:FakeWiki 'Private-Get-GESample.md')).Length

        $second | Should Be $first
    }
}
