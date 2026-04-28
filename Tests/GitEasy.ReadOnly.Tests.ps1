$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ModulePath = Join-Path $ProjectRoot 'GitEasy.psd1'

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
        Set-Content -LiteralPath (Join-Path $Path 'README.md') -Value 'history baseline' -Encoding UTF8
        Invoke-TestGit -ArgumentList @('add', '-A') | Out-Null
        Invoke-TestGit -ArgumentList @('commit', '-m', 'read only baseline') | Out-Null
        Invoke-TestGit -ArgumentList @('remote', 'add', 'origin', 'https://github.com/greenmtnsun/GitEasy.git') | Out-Null
    }
    finally {
        Pop-Location
    }
}

Describe 'read-only GitEasy commands' {
    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    BeforeEach {
        $script:TempRepo = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_ReadOnly_" + [guid]::NewGuid().ToString('N'))
        New-TestRepositoryWithCommit -Path $script:TempRepo
        Push-Location -LiteralPath $script:TempRepo
    }

    AfterEach {
        Pop-Location
        Remove-Item -LiteralPath $script:TempRepo -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Show-Remote reports origin fetch and push remotes' {
        $remotes = @(Show-Remote)
        $remotes.Count | Should -Be 2
        @($remotes | Where-Object { $_.Remote -eq 'origin' -and $_.Purpose -eq 'fetch' }).Count | Should -Be 1
        @($remotes | Where-Object { $_.Remote -eq 'origin' -and $_.Purpose -eq 'push' }).Count | Should -Be 1
        @($remotes | Select-Object -ExpandProperty Provider -Unique) | Should -Contain 'GitHub'
    }

    It 'Show-History returns recent commits' {
        $history = @(Show-History -Count 5)
        $history.Count | Should -BeGreaterThan 0
        ($history | Select-Object -First 1).Message | Should -Be 'read only baseline'
    }

    It 'Find-CodeChange reports a clean tree and then a dirty tree' {
        $clean = Find-CodeChange
        $clean.IsClean | Should -BeTrue

        Set-Content -LiteralPath (Join-Path $script:TempRepo 'change.txt') -Value 'pending change' -Encoding UTF8
        $dirty = Find-CodeChange

        $dirty.IsClean | Should -BeFalse
        $dirty.ChangeCount | Should -BeGreaterThan 0
        $dirty.UntrackedCount | Should -BeGreaterThan 0
    }
}
