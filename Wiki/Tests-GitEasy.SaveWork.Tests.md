# Tests-GitEasy.SaveWork.Tests

## Summary

Source file: `Tests\GitEasy.SaveWork.Tests.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Tests |
| Source file | `Tests\GitEasy.SaveWork.Tests.ps1` |
| File name | `GitEasy.SaveWork.Tests.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Invoke-TestGit | 4 | 31 | ArgumentList, AllowFailure |
| New-TestRepository | 33 | 47 | Path |

## Source

```powershell
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

Describe 'Save-Work' {
    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    BeforeEach {
        $script:TempRepo = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_SaveWork_" + [guid]::NewGuid().ToString('N'))
        New-TestRepository -Path $script:TempRepo
        Push-Location -LiteralPath $script:TempRepo
    }

    AfterEach {
        Pop-Location
        Remove-Item -LiteralPath $script:TempRepo -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates the first commit in a new repository with NoPush' {
        Set-Content -LiteralPath (Join-Path $script:TempRepo 'README.md') -Value @('# Test Repo', 'Save-Work test') -Encoding UTF8

        Save-Work 'initial pester commit' -NoPush

        $log = Invoke-TestGit -ArgumentList @('log', '--oneline', '-1')
        ($log.Output -join ' ') | Should Match 'initial pester commit'

        $status = Invoke-TestGit -ArgumentList @('status', '--porcelain=v1')
        @($status.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count | Should Be 0
    }

    It 'does not create a new commit when the tree is clean' {
        Set-Content -LiteralPath (Join-Path $script:TempRepo 'README.md') -Value 'clean test' -Encoding UTF8
        Save-Work 'clean baseline' -NoPush

        $before = (Invoke-TestGit -ArgumentList @('rev-parse', 'HEAD')).Output | Select-Object -First 1
        Save-Work 'should not commit' -NoPush
        $after = (Invoke-TestGit -ArgumentList @('rev-parse', 'HEAD')).Output | Select-Object -First 1

        $after | Should Be $before
    }

    It 'refuses to push without upstream unless NoPush or SetUpstream is used' {
        Set-Content -LiteralPath (Join-Path $script:TempRepo 'README.md') -Value 'no upstream test' -Encoding UTF8

        { Save-Work 'should fail without upstream' } | Should Throw
    }

    It 'refuses to save when a Git operation is in progress' {
        Set-Content -LiteralPath (Join-Path $script:TempRepo 'README.md') -Value 'busy baseline' -Encoding UTF8
        Save-Work 'busy baseline' -NoPush

        Set-Content -LiteralPath (Join-Path $script:TempRepo '.git\MERGE_HEAD') -Value '0000000000000000000000000000000000000000' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:TempRepo 'busy.txt') -Value 'busy change' -Encoding UTF8

        { Save-Work 'blocked by merge' -NoPush } | Should Throw
    }
}



```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
