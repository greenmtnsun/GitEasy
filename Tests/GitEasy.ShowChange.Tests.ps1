$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ModulePath  = Join-Path $ProjectRoot 'GitEasy.psd1'

function Invoke-TestGit {
    param(
        [Parameter(Mandatory)]
        [string[]]$ArgumentList,

        [switch]$AllowFailure
    )

    $oldPreference = $ErrorActionPreference

    try {
        $ErrorActionPreference = 'Continue'
        $output = & git @ArgumentList 2>&1
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

function New-TestRepositoryWithCommit {
    param([Parameter(Mandatory)] [string]$Path)

    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Push-Location -LiteralPath $Path

    try {
        Invoke-TestGit -ArgumentList @('init') | Out-Null
        Invoke-TestGit -ArgumentList @('config', 'user.name', 'GitEasy Pester') | Out-Null
        Invoke-TestGit -ArgumentList @('config', 'user.email', 'giteasy-pester@example.invalid') | Out-Null
        Set-Content -LiteralPath (Join-Path $Path 'README.md') -Value 'baseline content' -Encoding UTF8
        Invoke-TestGit -ArgumentList @('add', '-A') | Out-Null
        Invoke-TestGit -ArgumentList @('commit', '-m', 'baseline') | Out-Null
    }
    finally {
        Pop-Location
    }
}

Describe 'Show-Change' {
    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    BeforeEach {
        $script:Stem     = [guid]::NewGuid().ToString('N').Substring(0, 8)
        $script:TempRepo = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_SC_$script:Stem")

        New-TestRepositoryWithCommit -Path $script:TempRepo
        Push-Location -LiteralPath $script:TempRepo
    }

    AfterEach {
        Pop-Location
        Remove-Item -LiteralPath $script:TempRepo -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns no diff text when the working area is clean' {
        $r = Show-Change
        $hasContent = $false
        foreach ($entry in @($r)) {
            if ($entry -and ($entry | Get-Member -Name 'Diff' -ErrorAction SilentlyContinue)) {
                if (-not [string]::IsNullOrWhiteSpace($entry.Diff)) { $hasContent = $true }
            }
        }
        $hasContent | Should Be $false
    }

    It 'reports unstaged changes as structured objects with Path and Diff' {
        $target = Join-Path $script:TempRepo 'README.md'
        Set-Content -LiteralPath $target -Value "baseline content`r`nadded line" -Encoding UTF8

        $r = @(Show-Change)
        $r.Count -gt 0 | Should Be $true
        $entry = $r | Select-Object -First 1
        ($entry.PSObject.Properties.Name -contains 'Path') | Should Be $true
        ($entry.PSObject.Properties.Name -contains 'Diff') | Should Be $true
        $entry.Path | Should Match 'README\.md'
        $entry.Diff | Should Match 'added line'
    }

    It 'filters by -Path' {
        Set-Content -LiteralPath (Join-Path $script:TempRepo 'a.txt') -Value 'a content' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:TempRepo 'b.txt') -Value 'b content' -Encoding UTF8
        Invoke-TestGit -ArgumentList @('add', '-A') | Out-Null
        Invoke-TestGit -ArgumentList @('commit', '-m', 'add a and b') | Out-Null

        Set-Content -LiteralPath (Join-Path $script:TempRepo 'a.txt') -Value 'a edited' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:TempRepo 'b.txt') -Value 'b edited' -Encoding UTF8

        $r = @(Show-Change -Path 'a.txt')
        $r.Count | Should Be 1
        $r[0].Path | Should Match 'a\.txt'
    }

    It '-NextSave shows changes already prepared for the next saved point' {
        $target = Join-Path $script:TempRepo 'README.md'
        Set-Content -LiteralPath $target -Value "baseline content`r`nprepared change" -Encoding UTF8
        Invoke-TestGit -ArgumentList @('add', '-A') | Out-Null

        $unprepared = @(Show-Change)
        $prepared   = @(Show-Change -NextSave)

        $unprepared.Count | Should Be 0
        $prepared.Count -gt 0 | Should Be $true
        ($prepared | Select-Object -First 1).Diff | Should Match 'prepared change'
    }

    It '-Compact returns short summary instead of full diff' {
        $target = Join-Path $script:TempRepo 'README.md'
        Set-Content -LiteralPath $target -Value "baseline content`r`nshort change" -Encoding UTF8

        $r = Show-Change -Compact
        $r | Should Not BeNullOrEmpty
        ($r.PSObject.Properties.Name -contains 'Summary') | Should Be $true
        $r.Summary | Should Match 'README\.md'
    }

    It 'plain-English error when not inside a project folder' {
        $outside = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_SC_outside_" + [guid]::NewGuid().ToString('N').Substring(0,8))
        New-Item -Path $outside -ItemType Directory -Force | Out-Null
        Push-Location -LiteralPath $outside

        $thrown = $null
        try {
            $r = Show-Change
            if ($r -is [System.Management.Automation.ErrorRecord]) {
                $thrown = $r
            }
        } catch { $thrown = $_ }

        Pop-Location
        Remove-Item -LiteralPath $outside -Recurse -Force -ErrorAction SilentlyContinue

        $thrown | Should Not BeNullOrEmpty
    }
}

Describe 'Get-Updates' {
    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    BeforeEach {
        $script:Stem      = [guid]::NewGuid().ToString('N').Substring(0, 8)
        $script:TempBare  = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_GU_$($script:Stem)_remote.git")
        $script:TempA     = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_GU_$($script:Stem)_a")
        $script:TempB     = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_GU_$($script:Stem)_b")
        $script:TempLogs  = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_GU_$($script:Stem)_logs")

        # Bare remote
        New-Item -Path $script:TempBare -ItemType Directory -Force | Out-Null
        Push-Location -LiteralPath $script:TempBare
        Invoke-TestGit -ArgumentList @('init', '--bare') | Out-Null
        Pop-Location

        # Repo A — pushes a baseline to the bare
        New-TestRepositoryWithCommit -Path $script:TempA
        Push-Location -LiteralPath $script:TempA
        Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', $script:TempBare) | Out-Null
        Invoke-TestGit -ArgumentList @('push', '-u', 'origin', 'master') -AllowFailure | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Invoke-TestGit -ArgumentList @('push', '-u', 'origin', 'main') | Out-Null
        }
        Pop-Location

        # Repo B — clones from bare
        Push-Location -LiteralPath ([System.IO.Path]::GetTempPath())
        Invoke-TestGit -ArgumentList @('clone', $script:TempBare, $script:TempB) | Out-Null
        Pop-Location
        Push-Location -LiteralPath $script:TempB
        Invoke-TestGit -ArgumentList @('config', 'user.name', 'B') | Out-Null
        Invoke-TestGit -ArgumentList @('config', 'user.email', 'b@example.invalid') | Out-Null
        Pop-Location

        New-Item -Path $script:TempLogs -ItemType Directory -Force | Out-Null
        $env:GITEASY_LOG_PATH = $script:TempLogs
    }

    AfterEach {
        Remove-Item Env:\GITEASY_LOG_PATH -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:TempBare -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:TempA -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:TempB -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:TempLogs -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'reports zero new saved points when no peer activity has happened' {
        Push-Location -LiteralPath $script:TempB
        try {
            $r = Get-Updates
            $r | Should Not BeNullOrEmpty
            $r.NewSavedPoints | Should Be 0
        }
        finally {
            Pop-Location
        }
    }

    It 'detects new saved points pushed to the published location by a peer' {
        # A pushes a new commit to bare
        Push-Location -LiteralPath $script:TempA
        Set-Content -LiteralPath (Join-Path $script:TempA 'peer.txt') -Value 'peer change' -Encoding UTF8
        Invoke-TestGit -ArgumentList @('add', '-A') | Out-Null
        Invoke-TestGit -ArgumentList @('commit', '-m', 'peer commit') | Out-Null
        Invoke-TestGit -ArgumentList @('push') | Out-Null
        Pop-Location

        # B fetches via Get-Updates and should see 1 new saved point
        Push-Location -LiteralPath $script:TempB
        try {
            $r = Get-Updates
            $r.NewSavedPoints | Should Be 1
        }
        finally {
            Pop-Location
        }
    }

    It 'returns a structured object with Repository, Remote, NewSavedPoints, Message' {
        Push-Location -LiteralPath $script:TempB
        try {
            $r = Get-Updates
            ($r.PSObject.Properties.Name -contains 'Repository')      | Should Be $true
            ($r.PSObject.Properties.Name -contains 'Remote')          | Should Be $true
            ($r.PSObject.Properties.Name -contains 'NewSavedPoints')  | Should Be $true
            ($r.PSObject.Properties.Name -contains 'Message')         | Should Be $true
        }
        finally {
            Pop-Location
        }
    }

    It 'every invocation writes a log file' {
        Push-Location -LiteralPath $script:TempB
        try {
            Get-Updates | Out-Null
        }
        finally {
            Pop-Location
        }

        $logs = @(Get-ChildItem -LiteralPath $script:TempLogs -Filter 'Get-Updates-*.log' -File)
        $logs.Count -gt 0 | Should Be $true
        $body = Get-Content -LiteralPath ($logs | Sort-Object LastWriteTime | Select-Object -Last 1).FullName -Raw
        $body | Should Match 'Outcome: SUCCESS'
    }

    It 'plain-English error when no published location is configured' {
        # Remove origin from B
        Push-Location -LiteralPath $script:TempB
        try {
            Invoke-TestGit -ArgumentList @('remote', 'remove', 'origin') | Out-Null

            $thrown = $null
            try { Get-Updates } catch { $thrown = $_ }

            $thrown | Should Not BeNullOrEmpty
            $userMessage = $thrown.Exception.Message -replace '(?ms)Details:.*$',''
            $userMessage | Should Not Match '(?i)\bupstream\b'
            $userMessage | Should Not Match '(?i)\bHEAD\b'
        }
        finally {
            Pop-Location
        }
    }
}
