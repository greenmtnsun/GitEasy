BeforeAll {

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ModulePath  = Join-Path $ProjectRoot 'GitEasy.psd1'
}

Describe 'New-BugReport (unit contract)' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    It 'is exported by the GitEasy module' {
        @(Get-Command -Module GitEasy -Name 'New-BugReport').Count | Should -Be 1
    }

    It 'has CmdletBinding' {
        $cmd = Get-Command 'New-BugReport'
        $cmd.CmdletBinding | Should -Be $true
    }

    It 'supports ShouldProcess (-WhatIf and -Confirm available)' {
        $cmd = Get-Command 'New-BugReport'
        $cmd.Parameters.ContainsKey('WhatIf')  | Should -Be $true
        $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
    }

    It 'declares the -NoLog parameter' {
        $cmd = Get-Command 'New-BugReport'
        $cmd.Parameters.ContainsKey('NoLog') | Should -Be $true
    }

    It 'declares the -LogPath parameter' {
        $cmd = Get-Command 'New-BugReport'
        $cmd.Parameters.ContainsKey('LogPath') | Should -Be $true
    }

    It 'has a non-empty .SYNOPSIS' {
        $help = Get-Help 'New-BugReport' -ErrorAction SilentlyContinue
        $help.Synopsis | Should -Not -BeNullOrEmpty
    }

    It 'has at least one .EXAMPLE in CBH' {
        $help = Get-Help 'New-BugReport' -Full -ErrorAction SilentlyContinue
        @($help.examples.example).Count -gt 0 | Should -Be $true
    }
}

Describe 'New-BugReport (behaviour)' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    It '-WhatIf returns the GitEasy issue link without opening it' {
        $logDir = Join-Path $TestDrive 'logs-bug'

        $result = New-BugReport -WhatIf -NoLog -LogPath $logDir
        $result.Url | Should -Match 'github\.com/greenmtnsun/GitEasy/issues/new'
    }

    It 'includes a populated environment snapshot' {
        $logDir = Join-Path $TestDrive 'logs-bug2'

        $result = New-BugReport -WhatIf -NoLog -LogPath $logDir
        $result.Environment.PowerShellVersion | Should -Not -BeNullOrEmpty
    }
}
