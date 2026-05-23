BeforeAll {
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
            $r | Should -Be 'https://github.com/o/r.git'
        }

        It 'strips a bare user@ from an https authority' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://alice@github.com/o/r.git' }
            $r | Should -Be 'https://github.com/o/r.git'
        }

        It 'leaves a clean https URL unchanged' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://github.com/o/r.git' }
            $r | Should -Be 'https://github.com/o/r.git'
        }

        It 'leaves scp-like SSH (git@host:path) unchanged - that git@ is not a secret' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'git@github.com:o/r.git' }
            $r | Should -Be 'git@github.com:o/r.git'
        }

        It 'does not strip an @ that appears later in the path' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://github.com/o/a@b.git' }
            $r | Should -Be 'https://github.com/o/a@b.git'
        }

        It 'passes through empty/whitespace unchanged' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url '   ' }
            $r | Should -Be '   '
        }

        It 'the redacted result never contains the secret token' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://u:ghp_DEADBEEF@example.com/x.git' }
            $r | Should -Not -Match 'ghp_DEADBEEF'
        }
    }

    # -----------------------------------------------------------------------
    # F-03 unit: Format-GESafeLogLine redacts credential-bearing lines but
    # keeps the key and leaves protocol lines intact.
    # -----------------------------------------------------------------------
    Context 'Format-GESafeLogLine (F-03 log sanitiser)' {

        It 'redacts a password= value but keeps the key' {
            $r = InModuleScope GitEasy { 'password=ghp_SECRET' | Format-GESafeLogLine }
            $r | Should -Be 'password=[redacted]'
        }

        It 'redacts secret=, token=, bearer=, and Authorization:' {
            $r = InModuleScope GitEasy {
                @('secret=abc','token=def','bearer=ghi','Authorization: Bearer zzz') | Format-GESafeLogLine
            }
            ($r -join '|') | Should -Be 'secret=[redacted]|token=[redacted]|bearer=[redacted]|Authorization: [redacted]'
        }

        It 'is case-insensitive on the key' {
            $r = InModuleScope GitEasy { 'PASSWORD=ghp_X' | Format-GESafeLogLine }
            $r | Should -Be 'PASSWORD=[redacted]'
        }

        It 'leaves non-sensitive protocol lines unchanged' {
            $r = InModuleScope GitEasy { @('protocol=https','host=github.com') | Format-GESafeLogLine }
            ($r -join '|') | Should -Be 'protocol=https|host=github.com'
        }

        It 'the sanitised output never contains the secret value' {
            $r = InModuleScope GitEasy { 'password=ghp_DEADBEEF' | Format-GESafeLogLine }
            $r | Should -Not -Match 'ghp_DEADBEEF'
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

            $r.Count -gt 0 | Should -Be $true
            foreach ($entry in $r) {
                $entry.Url | Should -Not -Match 'ghp_REALSECRET'
                $entry.Url | Should -Not -Match 'x-access-token'
                $entry.Url | Should -Be 'https://github.com/o/r.git'
            }
        }

        It 'still classifies the provider correctly after redaction' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'https://u:tok@github.com/o/r.git') | Out-Null

            $r = @(Show-Remote)

            @($r | Where-Object { $_.Provider -eq 'GitHub' }).Count -gt 0 | Should -Be $true
        }

        It 'reports Provider None when no remote is configured' {
            $r = Show-Remote
            $r.Provider | Should -Be 'None'
            $r.Url | Should -BeNullOrEmpty
        }

        It 'returns one object per fetch/push entry for a clean remote' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'https://github.com/o/r.git') | Out-Null

            $r = @(Show-Remote)

            $r.Count | Should -Be 2
            @($r | Where-Object { $_.Purpose -eq 'fetch' }).Count | Should -Be 1
            @($r | Where-Object { $_.Purpose -eq 'push' }).Count  | Should -Be 1
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

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Match '(?i)HTTPS'
            $thrown.Exception.Message | Should -Not -Match 'ghp_REALSECRET'
            $thrown.Exception.Message | Should -Not -Match 'user:'
        }

        It 'the failure log for a non-HTTPS embedded-cred remote contains no secret (F-01)' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'http://user:ghp_REALSECRET@github.com/o/r.git') | Out-Null

            try { Reset-Login } catch { }

            $logs = @(Get-ChildItem -LiteralPath $script:Logs -Filter 'Reset-Login-*.log' -File)
            $logs.Count -gt 0 | Should -Be $true
            $body = Get-Content -LiteralPath $logs[-1].FullName -Raw
            $body | Should -Not -Match 'ghp_REALSECRET'
        }

        It 'the [uri] parse the F-02 fix relies on yields the bare host, not user:token@host' {
            # Reset-Login replaced the regex ^https://(?<Host>[^/]+)/ (which
            # captured "user:tok@host" as the host - leaking the secret into
            # the log and clearing the wrong entry) with [uri].Host. This
            # locks the .NET behaviour the fix depends on. Executing Reset-Login
            # past the parse would hit the real credential store, so the
            # host *value* on the success path is review-verified, not run here.
            $parsed = InModuleScope GitEasy { 'https://user:ghp_REALSECRET@github.example/o/r.git' -as [uri] }

            $parsed.Scheme | Should -Be 'https'
            $parsed.Host   | Should -Be 'github.example'
            $parsed.Host   | Should -Not -Match 'ghp_REALSECRET'
            $parsed.Host   | Should -Not -Match 'user:'
        }

        It 'plainly reports when no remote is configured' {
            $thrown = $null
            try { Reset-Login } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Not -Match '(?i)\bgit\b'
        }
    }

    # -----------------------------------------------------------------------
    # F-01 / F-05 edges: Format-GESafeUrl now handles URLs embedded mid-string
    # (the F-05 fix dropped the `^` anchor so a creds URL quoted inside an
    # error message is sanitised) plus alt-scheme URLs (ssh://, git+ssh://)
    # and IPv6 literal hosts.
    # -----------------------------------------------------------------------
    Context 'Format-GESafeUrl mid-string and alt-scheme (F-05 + F-01 edges)' {

        It 'strips a creds URL embedded in a git-style error message' {
            $r = InModuleScope GitEasy {
                Format-GESafeUrl -Url "fatal: unable to access 'https://x:tok@github.com/o/r.git/': SSL"
            }
            $r | Should -Be "fatal: unable to access 'https://github.com/o/r.git/': SSL"
            $r | Should -Not -Match 'x:tok'
        }

        It 'strips userinfo from an ssh:// scheme URL' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'ssh://user:pw@host/path' }
            $r | Should -Be 'ssh://host/path'
        }

        It 'strips userinfo from a git+ssh:// scheme URL' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'git+ssh://user:pw@host/path' }
            $r | Should -Be 'git+ssh://host/path'
        }

        It 'leaves an IPv6 literal host untouched when no userinfo is present' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://[::1]/o/r.git' }
            $r | Should -Be 'https://[::1]/o/r.git'
        }

        It 'strips userinfo from an IPv6 literal host URL' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://u:tok@[::1]/o/r.git' }
            $r | Should -Be 'https://[::1]/o/r.git'
        }

        It 'handles multiple URLs in the same string' {
            $r = InModuleScope GitEasy {
                Format-GESafeUrl -Url 'a https://u:t@x.com b https://u:t@y.com c'
            }
            $r | Should -Be 'a https://x.com b https://y.com c'
        }

        It 'leaves "%40" alone (percent-encoded @ is data, not the auth boundary)' {
            $r = InModuleScope GitEasy { Format-GESafeUrl -Url 'https://github.com/o/a%40b.git' }
            $r | Should -Be 'https://github.com/o/a%40b.git'
        }
    }

    # -----------------------------------------------------------------------
    # F-03 edges: Format-GESafeLogLine now also redacts Proxy-Authorization
    # headers (the regex previously only matched the bare "authorization"
    # alternation). The line-anchor remains by design — a literal
    # "password=foo" mid-sentence in narrative text is left alone.
    # -----------------------------------------------------------------------
    Context 'Format-GESafeLogLine edges (F-03)' {

        It 'redacts a Proxy-Authorization header' {
            $r = InModuleScope GitEasy { 'Proxy-Authorization: Bearer abc' | Format-GESafeLogLine }
            $r | Should -Be 'Proxy-Authorization: [redacted]'
        }

        It 'redacts Proxy-Authorization case-insensitively' {
            $r = InModuleScope GitEasy { 'PROXY-AUTHORIZATION: Bearer xyz' | Format-GESafeLogLine }
            $r | Should -Be 'PROXY-AUTHORIZATION: [redacted]'
        }

        It 'leaves a mid-sentence "password=" alone (line-shape intent lock)' {
            $r = InModuleScope GitEasy { 'Operator said password=foo on the phone' | Format-GESafeLogLine }
            $r | Should -Be 'Operator said password=foo on the phone'
        }
    }

    # -----------------------------------------------------------------------
    # F-04 kill-test: Convert-GERemoteToSsh now uses [uri] parsing and
    # refuses URLs whose authority embeds userinfo. The old regex
    # ^https://(?<Host>[^/]+)/ would greedily capture "user:tok@host" as
    # the host, the same shape as the F-02 Reset-Login bug.
    # -----------------------------------------------------------------------
    Context 'Convert-GERemoteToSsh refuses embedded credentials (F-04 kill-test)' {

        It 'converts a clean HTTPS URL to its SSH form' {
            $r = InModuleScope GitEasy { Convert-GERemoteToSsh -RemoteUrl 'https://github.com/o/r.git' }
            $r | Should -Be 'git@github.com:o/r.git'
        }

        It 'returns an already-SSH URL unchanged' {
            $r = InModuleScope GitEasy { Convert-GERemoteToSsh -RemoteUrl 'git@github.com:o/r.git' }
            $r | Should -Be 'git@github.com:o/r.git'
        }

        It 'throws when the URL embeds credentials in userinfo' {
            $thrown = $null
            try {
                InModuleScope GitEasy { Convert-GERemoteToSsh -RemoteUrl 'https://x:ghp_REALSECRET@github.com/o/r.git' }
            } catch { $thrown = $_ }
            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Match '(?i)embed|password|token'
            $thrown.Exception.Message | Should -Not -Match 'ghp_REALSECRET'
        }

        It 'throws on a non-HTTPS URL' {
            $thrown = $null
            try {
                InModuleScope GitEasy { Convert-GERemoteToSsh -RemoteUrl 'ftp://host/path' }
            } catch { $thrown = $_ }
            $thrown | Should -Not -BeNullOrEmpty
        }

        It 'the [uri] parse the F-04 fix relies on isolates UserInfo from Host' {
            $parsed = InModuleScope GitEasy { 'https://x:ghp_REALSECRET@github.example/o/r.git' -as [uri] }
            $parsed.Host | Should -Be 'github.example'
            $parsed.UserInfo | Should -Be 'x:ghp_REALSECRET'
        }
    }

    # -----------------------------------------------------------------------
    # F-02 edges: Reset-Login relies on [uri].Host for the credential reject
    # target. Lock the .NET behaviour for hosts that have caused regex
    # parsers to misbehave elsewhere: IDN punycode, IPv6 literals, ports in
    # authority.
    # -----------------------------------------------------------------------
    Context '[uri].Host edge cases for Reset-Login (F-02 edges)' {

        It 'punycode IDN host is preserved verbatim' {
            $parsed = 'https://xn--80akhbyknj4f.example/o/r.git' -as [uri]
            $parsed.Host | Should -Be 'xn--80akhbyknj4f.example'
        }

        It 'IPv6 literal host is preserved as a bracketed literal' {
            # PS 7 returns '[::1]'; PS 5.1's older .NET returns the expanded
            # '[0000:0000:0000:0000:0000:0000:0000:0001]'. Both are valid
            # IPv6 representations of the same address and both round-trip
            # through .NET Uri unambiguously, so the assertion accepts both.
            $parsed = 'https://[::1]/o/r.git' -as [uri]
            $parsed.Host | Should -Match '^\[[0-9a-f:]+\]$'
        }

        It 'port in authority is split out from .Host' {
            $parsed = 'https://github.example:8443/o/r.git' -as [uri]
            $parsed.Host | Should -Be 'github.example'
            $parsed.Port | Should -Be 8443
        }
    }

    # -----------------------------------------------------------------------
    # F-05 kill-test: Test-Login must not surface an embedded credential
    # through its returned object, no matter what is sitting in .git/config.
    # Test-Login will return Passed=false here (ls-remote cannot reach an
    # invented host), but the Url field must be sanitised regardless.
    # -----------------------------------------------------------------------
    Context 'Test-Login does not leak embedded credentials (F-05 kill-test)' {

        BeforeEach {
            $script:Stem = [guid]::NewGuid().ToString('N').Substring(0, 8)
            $script:Repo = Join-Path ([IO.Path]::GetTempPath()) "GitEasy_TL_$script:Stem"
            New-TestRepository -Path $script:Repo
            Push-Location -LiteralPath $script:Repo
        }

        AfterEach {
            Pop-Location
            Remove-Item -LiteralPath $script:Repo -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'redacts an embedded token from the Url field of the returned object' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'https://x-access-token:ghp_REALSECRET@github.invalid/o/r.git') | Out-Null

            $r = Test-Login

            $r.Url | Should -Not -Match 'ghp_REALSECRET'
            $r.Url | Should -Not -Match 'x-access-token'
            $r.Url | Should -Be 'https://github.invalid/o/r.git'
        }

        It 'redacts an embedded token from any URL quoted in the Message field' {
            Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'https://x-access-token:ghp_REALSECRET@github.invalid/o/r.git') | Out-Null

            $r = Test-Login

            $r.Passed | Should -Be $false
            $r.Message | Should -Not -Match 'ghp_REALSECRET'
        }
    }

    # -----------------------------------------------------------------------
    # F-06 kill-test: Invoke-GEGit sanitises URL-shaped args before they
    # land in the log step header or the thrown error message. A bogus
    # `remote set-url` against a non-existent remote fails fast (no
    # network), so the throw path is exercised cleanly.
    # -----------------------------------------------------------------------
    Context 'Invoke-GEGit sanitises URL-shaped args (F-06 kill-test)' {

        BeforeEach {
            $script:Stem = [guid]::NewGuid().ToString('N').Substring(0, 8)
            $script:Repo = Join-Path ([IO.Path]::GetTempPath()) "GitEasy_IGS_$script:Stem"
            New-TestRepository -Path $script:Repo
            Push-Location -LiteralPath $script:Repo
        }

        AfterEach {
            Pop-Location
            Remove-Item -LiteralPath $script:Repo -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'redacts a creds-URL arg in the thrown error message' {
            $thrown = $null
            $repoPath = $script:Repo
            try {
                & (Get-Module GitEasy) {
                    param($wd)
                    Invoke-GEGit -ArgumentList @('remote','set-url','noSuchRemote','https://x:ghp_REALSECRET@host.invalid/r.git') -WorkingDirectory $wd
                } $repoPath
            } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Not -Match 'ghp_REALSECRET'
            $thrown.Exception.Message | Should -Not -Match 'x:'
        }
    }

    # -----------------------------------------------------------------------
    # Test-GERemoteUrlSafe accept/reject matrix. Previously covered only
    # transitively through Set-Token / Set-Ssh; this locks the helper's
    # contract directly.
    # -----------------------------------------------------------------------
    Context 'Test-GERemoteUrlSafe accept/reject matrix' {

        It 'accepts a clean https URL' {
            $r = InModuleScope GitEasy { Test-GERemoteUrlSafe -RemoteUrl 'https://github.com/o/r.git' }
            $r | Should -Be $true
        }

        It 'accepts the scp-style SSH form' {
            $r = InModuleScope GitEasy { Test-GERemoteUrlSafe -RemoteUrl 'git@github.com:o/r.git' }
            $r | Should -Be $true
        }

        It 'rejects an embedded-cred https URL' {
            $thrown = $null
            try {
                InModuleScope GitEasy { Test-GERemoteUrlSafe -RemoteUrl 'https://x:tok@github.com/o/r.git' }
            } catch { $thrown = $_ }
            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Match '(?i)embed|password|token'
        }

        It 'rejects a non-HTTPS, non-SSH URL' {
            $thrown = $null
            try {
                InModuleScope GitEasy { Test-GERemoteUrlSafe -RemoteUrl 'ftp://host/path' }
            } catch { $thrown = $_ }
            $thrown | Should -Not -BeNullOrEmpty
        }

        It 'rejects empty/whitespace input' {
            $thrown = $null
            try {
                InModuleScope GitEasy { Test-GERemoteUrlSafe -RemoteUrl '   ' }
            } catch { $thrown = $_ }
            $thrown | Should -Not -BeNullOrEmpty
        }
    }
}
