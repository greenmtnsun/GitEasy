BeforeAll {

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ModulePath  = Join-Path $ProjectRoot 'GitEasy.psd1'
}

Describe 'Enable-GitEasy (unit contract)' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    It 'is exported by the GitEasy module' {
        @(Get-Command -Module GitEasy -Name 'Enable-GitEasy').Count | Should -Be 1
    }

    It 'has CmdletBinding' {
        $cmd = Get-Command 'Enable-GitEasy'
        $cmd.CmdletBinding | Should -Be $true
    }

    It 'supports ShouldProcess (-WhatIf and -Confirm available)' {
        $cmd = Get-Command 'Enable-GitEasy'
        $cmd.Parameters.ContainsKey('WhatIf')  | Should -Be $true
        $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
    }

    It 'declares the -ProfilePath parameter' {
        $cmd = Get-Command 'Enable-GitEasy'
        $cmd.Parameters.ContainsKey('ProfilePath') | Should -Be $true
    }

    It 'declares the -LogPath parameter' {
        $cmd = Get-Command 'Enable-GitEasy'
        $cmd.Parameters.ContainsKey('LogPath') | Should -Be $true
    }

    It 'has a non-empty .SYNOPSIS' {
        $help = Get-Help 'Enable-GitEasy' -ErrorAction SilentlyContinue
        $help.Synopsis | Should -Not -BeNullOrEmpty
    }

    It 'has at least one .EXAMPLE in CBH' {
        $help = Get-Help 'Enable-GitEasy' -Full -ErrorAction SilentlyContinue
        @($help.examples.example).Count -gt 0 | Should -Be $true
    }
}

Describe 'Enable-GitEasy (behaviour)' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    It 'adds the load block to a fresh startup file' {
        $profilePath = Join-Path $TestDrive 'profile-enable.ps1'
        $logDir      = Join-Path $TestDrive 'logs-enable'

        $result = Enable-GitEasy -ProfilePath $profilePath -LogPath $logDir
        $result.AlreadyEnabled | Should -Be $false

        Test-Path -LiteralPath $profilePath -PathType Leaf | Should -Be $true
        (Get-Content -LiteralPath $profilePath -Raw) | Should -Match 'GitEasy'
        (Get-Content -LiteralPath $profilePath -Raw) | Should -Match 'Import-Module GitEasy'
    }

    It 'is idempotent on a second run' {
        $profilePath = Join-Path $TestDrive 'profile-enable2.ps1'
        $logDir      = Join-Path $TestDrive 'logs-enable2'

        Enable-GitEasy -ProfilePath $profilePath -LogPath $logDir | Out-Null
        $second = Enable-GitEasy -ProfilePath $profilePath -LogPath $logDir
        $second.AlreadyEnabled | Should -Be $true
    }

    It '-WhatIf does not create the startup file' {
        $profilePath = Join-Path $TestDrive 'profile-enable-whatif.ps1'
        $logDir      = Join-Path $TestDrive 'logs-enable-whatif'

        Enable-GitEasy -ProfilePath $profilePath -LogPath $logDir -WhatIf | Out-Null
        Test-Path -LiteralPath $profilePath -PathType Leaf | Should -Be $false
    }
}
