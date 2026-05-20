$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ModulePath  = Join-Path $ProjectRoot 'GitEasy.psd1'

# Helpers mirror GitEasy.SaveWork.Tests.ps1. These tests cover the
# credential-surface hardening (F-01 embedded-cred leak, F-02 host parse,
# F-03 credential-output in logs). They must NEVER reach a real
# `git credential reject` / cmdkey call — that would mutate the operator's
# real credential store. Every Reset-Login path exercised here either
# throws before the credential step or is short-circuited by -WhatIf.
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
    return [PSCustomObject]@{ ExitCode = $exitCode; Output = @($output) }
}

function New-TestRepository {
    param([Parameter(Mandatory)] [string]$Path)
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Push-Location -LiteralPath $Path
    try {
        Invoke-TestGit -ArgumentList @('init') | Out-Null
        Invoke-TestGit -ArgumentList @('config', 'user.name', 'GitEasy Pester') | Out-Null
        Invoke-TestGit -ArgumentList @('config', 'user.email', 'giteasy-pester@example.invalid') | Out-Null
    }
    finally {
        Pop-Location
    }
}

Describe 'Credential-surface hardening' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    # -----------------------------------------------------------------------
    # F-01 unit: Format-GESafeUrl strips embedded credentials, leaves
    # everything else (clean URLs, scp-like SSH) intact.
    # -----------------------------------------------------------------------
    Context 'Format-GESafeUrl (F-01 redaction helper)' {

        It 'strips user:token@ from an https authority' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://x-access-token:ghp_REALSECRET@github.com/o/r.git' }
            $r | Should Be 'https://github.com/o/r.git'
        }

        It 'strips a bare user@ from an https authority' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://alice@github.com/o/r.git' }
            $r | Should Be 'https://github.com/o/r.git'
        }

        It 'leaves a clean https URL unchanged' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://github.com/o/r.git' }
            $r | Should Be 'https://github.com/o/r.git'
        }

        It 'leaves scp-like SSH (git@host:path) unchanged - that git@ is not a secret' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'git@github.com:o/r.git' }
            $r | Should Be 'git@github.com:o/r.git'
        }

        It 'does not strip an @ that appears later in the path' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://github.com/o/a@b.git' }
            $r | Should Be 'https://github.com/o/a@b.git'
        }

        It 'passes through empty/whitespace unchanged' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url '   ' }
            $r | Should Be '   '
        }

        It 'the redacted result never contains the secret token' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://u:ghp_DEADBEEF@example.com/x.git' }
            $r | Should Not Match 'ghp_DEADBEEF'
        }
    }

    # -----------------------------------------------------------------------
    # F-03 unit: Format-GESafeLogLine redacts credential-bearing lines but
    # keeps the key and leaves protocol lines intact.
    # -----------------------------------------------------------------------
    Context 'Format-GESafeLogLine (F-03 log sanitiser)' {

        It 'redacts a password= value but keeps the key' {
            $r = InModuleScope GitEasy { 'password=ghp_SECRET' | Format-GESafeLogLine }
            $r | Should Be 'password=[redacted]'
        }

        It 'redacts secret=, token=, bearer=, and Authorization:' {
            $r = InModuleScope GitEasy {
                @('secret=abc','token=def','bearer=ghi','Authorization: Bearer zzz') | Format-GESafeLogLine
            }
            ($r -join '|') | Should Be 'secret=[redacted]|token=[redacted]|bearer=[redacted]|Authorization: [redacted]'
        }

        It 'is case-insensitive on the key' {
            $r = InModuleScope GitEasy { 'PASSWORD=ghp_X' | Format-GESafeLogLine }
            $r | Should Be 'PASSWORD=[redacted]'
        }

        It 'leaves non-sensitive protocol lines unchanged' {
            $r = InModuleScope GitEasy { @('protocol=https','host=github.com') | Format-GESafeLogLine }
            ($r -join '|') | Should Be 'protocol=https|host=github.com'
        }

        It 'the sanitised output never contains the secret value' {
            $r = InModuleScope GitEasy { 'password=ghp_DEADBEEF' | Format-GESafeLogLine }
            $r | Should Not Match 'ghp_DEADBEEF'
        }
    }

    # -----------------------------------------------------------------------
    # F-01 kill-test at the display boundary: a pre-existing embedded-cred
    # remote URL in .git/config must not surface through Show-Remote.
    # Show-Remote performs no credential operations, so this is safe.
    # -----------------------------------------------------------------------
    Context 'Show-Remote does not leak embedded credentials (F-01 kill-test)' {

        BeforeEach {
            $script:Stem = [guid]::NewGuid().ToString('N').Substring(0, 8)
            $script:Repo = Join-Path ([IO.Path]::GetTempPath()) "GitEasy_CS_$script:Stem"
            New-TestRepository -Path $script:Repo
            Push-Location -LiteralPath $script:Repo
        }

        AfterEach {
            Pop-Location
            Remove-Item -LiteralPath $script:Repo -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'redacts an embedded token from the reported Url' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'https://x-access-token:ghp_REALSECRET@github.com/o/r.git') | Out-Null

            $r = @(Show-Remote)

            $r.Count -gt 0 | Should Be $true
            foreach ($entry in $r) {
                $entry.Url | Should Not Match 'ghp_REALSECRET'
                $entry.Url | Should Not Match 'x-access-token'
                $entry.Url | Should Be 'https://github.com/o/r.git'
            }
        }

        It 'still classifies the provider correctly after redaction' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'https://u:tok@github.com/o/r.git') | Out-Null

            $r = @(Show-Remote)

            @($r | Where-Object { $_.Provider -eq 'GitHub' }).Count -gt 0 | Should Be $true
        }

        It 'reports Provider None when no remote is configured' {
            $r = Show-Remote
            $r.Provider | Should Be 'None'
            $r.Url | Should BeNullOrEmpty
        }

        It 'returns one object per fetch/push entry for a clean remote' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'https://github.com/o/r.git') | Out-Null

            $r = @(Show-Remote)

            $r.Count | Should Be 2
            @($r | Where-Object { $_.Purpose -eq 'fetch' }).Count | Should Be 1
            @($r | Where-Object { $_.Purpose -eq 'push' }).Count  | Should Be 1
        }
    }

    # -----------------------------------------------------------------------
    # F-01 / F-02 kill-test on Reset-Login. Only the throw-before-credential
    # path and the -WhatIf short-circuit are exercised, so no real
    # credential store is ever touched.
    # -----------------------------------------------------------------------
    Context 'Reset-Login does not leak credentials (F-01/F-02 kill-test)' {

        BeforeEach {
            $script:Stem = [guid]::NewGuid().ToString('N').Substring(0, 8)
            $script:Repo = Join-Path ([IO.Path]::GetTempPath()) "GitEasy_RL_$script:Stem"
            $script:Logs = Join-Path ([IO.Path]::GetTempPath()) "GitEasy_RL_$($script:Stem)_logs"
            New-TestRepository -Path $script:Repo
            New-Item -Path $script:Logs -ItemType Directory -Force | Out-Null
            $env:GITEASY_LOG_PATH = $script:Logs
            Push-Location -LiteralPath $script:Repo
        }

        AfterEach {
            Pop-Location
            Remove-Item Env:\GITEASY_LOG_PATH -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:Repo -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:Logs -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'a non-HTTPS embedded-credential remote is rejected with a redacted message (F-01)' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'http://user:ghp_REALSECRET@github.com/o/r.git') | Out-Null

            $thrown = $null
            try { Reset-Login } catch { $thrown = $_ }

            $thrown | Should Not BeNullOrEmpty
            $thrown.Exception.Message | Should Match '(?i)HTTPS'
            $thrown.Exception.Message | Should Not Match 'ghp_REALSECRET'
            $thrown.Exception.Message | Should Not Match 'user:'
        }

        It 'the failure log for a non-HTTPS embedded-cred remote contains no secret (F-01)' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'http://user:ghp_REALSECRET@github.com/o/r.git') | Out-Null

            try { Reset-Login } catch { }

            $logs = @(Get-ChildItem -LiteralPath $script:Logs -Filter 'Reset-Login-*.log' -File)
            $logs.Count -gt 0 | Should Be $true
            $body = Get-Content -LiteralPath $logs[-1].FullName -Raw
            $body | Should Not Match 'ghp_REALSECRET'
        }

        It 'the [uri] parse the F-02 fix relies on yields the bare host, not user:token@host' {
            # Reset-Login replaced the regex ^https://(?<Host>[^/]+)/ (which
            # captured "user:tok@host" as the host - leaking the secret into
            # the log and clearing the wrong entry) with [uri].Host. This
            # locks the .NET behaviour the fix depends on. Executing Reset-Login
            # past the parse would hit the real credential store, so the
            # host *value* on the success path is review-verified, not run here.
            $parsed = InModuleScope GitEasy { 'https://user:ghp_REALSECRET@github.example/o/r.git' -as [uri] }

            $parsed.Scheme | Should Be 'https'
            $parsed.Host   | Should Be 'github.example'
            $parsed.Host   | Should Not Match 'ghp_REALSECRET'
            $parsed.Host   | Should Not Match 'user:'
        }

        It 'plainly reports when no remote is configured' {
            $thrown = $null
            try { Reset-Login } catch { $thrown = $_ }

            $thrown | Should Not BeNullOrEmpty
            $thrown.Exception.Message | Should Not Match '(?i)\bgit\b'
        }
    }
}
