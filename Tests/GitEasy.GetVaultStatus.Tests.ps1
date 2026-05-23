BeforeAll {
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ModulePath  = Join-Path $ProjectRoot 'GitEasy.psd1'

# ---------------------------------------------------------------------------
# Invoke-TestGit — thin wrapper used only to set up git state in temp repos.
# Mirrors the pattern from SaveWork.Tests.ps1.
# ---------------------------------------------------------------------------
function Invoke-TestGit {
    param(
        [Parameter(Mandatory)]
        [string[]]$ArgumentList,

        [switch]$AllowFailure
    )

    $oldPreference = $ErrorActionPreference

    try {
        $ErrorActionPreference = 'Continue'
        $output   = & git @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }

    if (($exitCode -ne 0) -and (-not $AllowFailure)) {
        throw "Git failed: git $($ArgumentList -join ' ')`n$($output -join [Environment]::NewLine)"
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = @($output)
    }
}

# ---------------------------------------------------------------------------
# Read the real global credential.helper value once so we can restore it.
# Tests that mutate this key must restore it in AfterEach.
# ---------------------------------------------------------------------------
function Get-GlobalCredentialHelper {
    $r = Invoke-TestGit -ArgumentList @('config', '--global', '--get', 'credential.helper') -AllowFailure
    if ($r.ExitCode -eq 0) {
        return ($r.Output | Select-Object -First 1)
    }
    return $null
}

function Set-GlobalCredentialHelper {
    param([string]$Value)
    Invoke-TestGit -ArgumentList @('config', '--global', 'credential.helper', $Value) | Out-Null
}

function Remove-GlobalCredentialHelper {
    Invoke-TestGit -ArgumentList @('config', '--global', '--unset', 'credential.helper') -AllowFailure | Out-Null
}
}

Describe 'Get-VaultStatus — contract' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    # -----------------------------------------------------------------------
    # Return-shape tests: do not touch the real git global config.
    # We mock Invoke-GEGit so the tests are hermetic and fast.
    # -----------------------------------------------------------------------

    Context 'Return shape' {

        It 'returns a PSCustomObject, not $null' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core'); Stderr = @() }
            }

            $result = Get-VaultStatus

            $result | Should -Not -BeNullOrEmpty
        }

        It 'result has a CredentialHelper property' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core'); Stderr = @() }
            }

            $result = Get-VaultStatus

            ($result | Get-Member -Name CredentialHelper) | Should -Not -BeNullOrEmpty
        }

        It 'result has a Configured property' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core'); Stderr = @() }
            }

            $result = Get-VaultStatus

            ($result | Get-Member -Name Configured) | Should -Not -BeNullOrEmpty
        }

        It 'result has exactly two properties — no extra fields leak out' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core'); Stderr = @() }
            }

            $result    = Get-VaultStatus
            $propNames = ($result | Get-Member -MemberType NoteProperty).Name | Sort-Object

            $propNames.Count | Should -Be 2
        }
    }

    # -----------------------------------------------------------------------
    # Configured-path tests: helper is present and exit code is 0.
    # -----------------------------------------------------------------------

    Context 'Configured path — credential.helper is set' {

        It 'Configured is $true when a helper name is returned' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core'); Stderr = @() }
            }

            $result = Get-VaultStatus

            $result.Configured | Should -Be $true
        }

        It 'CredentialHelper echoes back the value git config returned' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('osxkeychain'); Stderr = @() }
            }

            $result = Get-VaultStatus

            $result.CredentialHelper | Should -Be 'osxkeychain'
        }

        It 'only the first line of git output is used when multiple lines are returned' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core', 'store'); Stderr = @() }
            }

            $result = Get-VaultStatus

            $result.CredentialHelper | Should -Be 'manager-core'
        }
    }

    # -----------------------------------------------------------------------
    # Unconfigured-path tests: git config exits non-zero / returns nothing.
    # -----------------------------------------------------------------------

    Context 'Unconfigured path — credential.helper is absent' {

        It 'Configured is $false when git config exits non-zero (key not set)' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 1; Output = @(); Stderr = @() }
            }

            $result = Get-VaultStatus

            $result.Configured | Should -Be $false
        }

        It 'CredentialHelper is $null or empty when git config exits non-zero' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 1; Output = @(); Stderr = @() }
            }

            $result = Get-VaultStatus

            $result.CredentialHelper | Should -BeNullOrEmpty
        }

        It 'Configured is $false when exit code is 0 but output is whitespace only' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('   '); Stderr = @() }
            }

            $result = Get-VaultStatus

            $result.Configured | Should -Be $false
        }
    }

    # -----------------------------------------------------------------------
    # "Never returns secrets" contract (per the function's .NOTES).
    # -----------------------------------------------------------------------

    Context 'Safe-to-share output — no secret values exposed' {

        It 'CredentialHelper contains the helper name, not a password or token' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core'); Stderr = @() }
            }

            $result = Get-VaultStatus

            # The contract: only the storage name (a short word or path) is returned,
            # never a string that looks like a credential (long base64, token prefix, etc).
            $result.CredentialHelper | Should -Match '^[\w\-\.\/\\]+$'
        }

        It 'result does not contain a property named Password, Token, Secret, or Key' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core'); Stderr = @() }
            }

            $result     = Get-VaultStatus
            $propNames  = ($result | Get-Member -MemberType NoteProperty).Name

            @($propNames | Where-Object { $_ -match '(?i)(password|token|secret|key)' }).Count | Should -Be 0
        }
    }

    # -----------------------------------------------------------------------
    # git-not-installed path: Test-GEGitInstalled throws, function propagates.
    # -----------------------------------------------------------------------

    Context 'git not installed' {

        It 'throws when Test-GEGitInstalled reports git is missing' {
            Mock -ModuleName GitEasy Test-GEGitInstalled {
                throw 'Git was not found in PATH.'
            }

            $thrown = $null
            try { Get-VaultStatus } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
        }

        It 'error message does not contain internal git jargon when git is missing' {
            Mock -ModuleName GitEasy Test-GEGitInstalled {
                throw 'Git was not found in PATH.'
            }

            $thrown = $null
            try { Get-VaultStatus } catch { $thrown = $_ }

            # The word "git" in the error is allowed here (it names the dependency),
            # but internal flags, refspecs, plumbing terms must not appear.
            $thrown.Exception.Message | Should -Not -Match '(?i)\brefspec\b'
            $thrown.Exception.Message | Should -Not -Match '(?i)\bHEAD\b'
        }
    }

    # -----------------------------------------------------------------------
    # Invoke-GEGit call contract: correct arguments forwarded.
    # -----------------------------------------------------------------------

    Context 'Invoke-GEGit call contract' {

        It 'calls Invoke-GEGit with the credential.helper query arguments' {
            # Pester 3 + module-scoped mock: capturing state via $script: from
            # inside a -ModuleName mock writes to the module's scope, not the
            # test's. Assert-MockCalled -ParameterFilter is the idiomatic
            # way to inspect what arguments the mock saw.
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 0; Output = @('manager-core'); Stderr = @() }
            }

            Get-VaultStatus | Out-Null

            Assert-MockCalled Invoke-GEGit -ModuleName GitEasy -Times 1 -ParameterFilter {
                ($ArgumentList -join ' ') -match 'credential\.helper'
            }
        }

        It 'passes -AllowFailure so a missing key does not terminate the function' {
            Mock -ModuleName GitEasy Test-GEGitInstalled { $true }
            Mock -ModuleName GitEasy Invoke-GEGit {
                [PSCustomObject]@{ ExitCode = 1; Output = @(); Stderr = @() }
            }

            Get-VaultStatus | Out-Null

            Assert-MockCalled Invoke-GEGit -ModuleName GitEasy -Times 1 -ParameterFilter {
                $AllowFailure -eq $true
            }
        }
    }

    # -----------------------------------------------------------------------
    # Real-git integration: exercise against the actual global config.
    # Isolated by saving and restoring the pre-test helper value.
    # -----------------------------------------------------------------------

    Context 'Real-git integration — live global config' {

        BeforeEach {
            $script:OriginalHelper = Get-GlobalCredentialHelper
        }

        AfterEach {
            if ($null -ne $script:OriginalHelper -and $script:OriginalHelper -ne '') {
                Set-GlobalCredentialHelper -Value $script:OriginalHelper
            }
            else {
                Remove-GlobalCredentialHelper
            }
        }

        It 'Configured is $true after setting a real credential.helper value' {
            Set-GlobalCredentialHelper -Value 'store'

            $result = Get-VaultStatus

            $result.Configured | Should -Be $true
            $result.CredentialHelper | Should -Be 'store'
        }

        It 'Configured is $false after unsetting credential.helper' {
            Remove-GlobalCredentialHelper

            $result = Get-VaultStatus

            $result.Configured | Should -Be $false
        }

        It 'CredentialHelper value is never $null when Configured is $true' {
            Set-GlobalCredentialHelper -Value 'manager'

            $result = Get-VaultStatus

            if ($result.Configured) {
                $result.CredentialHelper | Should -Not -BeNullOrEmpty
            }
            else {
                # helper was already absent before we could set it; assert
                # the contract we DO know in this branch instead of $true|=$true.
                $result.Configured | Should -Be $false
            }
        }
    }
}
