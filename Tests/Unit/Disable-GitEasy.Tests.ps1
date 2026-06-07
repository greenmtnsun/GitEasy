BeforeAll {

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ModulePath  = Join-Path $ProjectRoot 'GitEasy.psd1'
}

Describe 'Disable-GitEasy (unit contract)' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    It 'is exported by the GitEasy module' {
        @(Get-Command -Module GitEasy -Name 'Disable-GitEasy').Count | Should -Be 1
    }

    It 'has CmdletBinding' {
        $cmd = Get-Command 'Disable-GitEasy'
        $cmd.CmdletBinding | Should -Be $true
    }

    It 'supports ShouldProcess (-WhatIf and -Confirm available)' {
        $cmd = Get-Command 'Disable-GitEasy'
        $cmd.Parameters.ContainsKey('WhatIf')  | Should -Be $true
        $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
    }

    It 'declares the -ProfilePath parameter' {
        $cmd = Get-Command 'Disable-GitEasy'
        $cmd.Parameters.ContainsKey('ProfilePath') | Should -Be $true
    }

    It 'declares the -LogPath parameter' {
        $cmd = Get-Command 'Disable-GitEasy'
        $cmd.Parameters.ContainsKey('LogPath') | Should -Be $true
    }

    It 'has a non-empty .SYNOPSIS' {
        $help = Get-Help 'Disable-GitEasy' -ErrorAction SilentlyContinue
        $help.Synopsis | Should -Not -BeNullOrEmpty
    }

    It 'has at least one .EXAMPLE in CBH' {
        $help = Get-Help 'Disable-GitEasy' -Full -ErrorAction SilentlyContinue
        @($help.examples.example).Count -gt 0 | Should -Be $true
    }
}

Describe 'Disable-GitEasy (behaviour)' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    It 'removes a block that Enable-GitEasy added, leaving other lines intact' {
        $profilePath = Join-Path $TestDrive 'profile-disable.ps1'
        $logDir      = Join-Path $TestDrive 'logs-disable'

        Set-Content -LiteralPath $profilePath -Value '# my own setup line' -Encoding UTF8
        Enable-GitEasy -ProfilePath $profilePath -LogPath $logDir | Out-Null

        $result = Disable-GitEasy -ProfilePath $profilePath -LogPath $logDir
        $result.AlreadyDisabled | Should -Be $false

        $content = Get-Content -LiteralPath $profilePath -Raw
        $content | Should -Match '# my own setup line'
        $content | Should -Not -Match 'Import-Module GitEasy'
    }

    It 'reports nothing to remove when the startup file does not exist' {
        $profilePath = Join-Path $TestDrive 'profile-missing.ps1'
        $logDir      = Join-Path $TestDrive 'logs-disable-missing'

        $result = Disable-GitEasy -ProfilePath $profilePath -LogPath $logDir
        $result.AlreadyDisabled | Should -Be $true
    }
}
