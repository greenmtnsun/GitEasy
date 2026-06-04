BeforeAll {
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ModulePath  = Join-Path $ProjectRoot 'GitEasy.psd1'

# ---------------------------------------------------------------------------
# Invoke-TestGit / New-TestRepository — same setup helpers used by
# GitEasy.SaveWork.Tests.ps1. Assert-GESafeSave is exercised transitively
# there through Save-Work; this suite asserts its own contract directly.
# ---------------------------------------------------------------------------
function Invoke-TestGit {
    <#
    .DESCRIPTION
    Test helper. Runs git with the given arguments and returns exit code and output.
    Steps:
    1. Run git capturing combined output.
    2. Throw on non-zero exit unless -AllowFailure is set.
    3. Return a result object with the exit code and output array.
    #>
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

function New-TestRepository {
    <#
    .DESCRIPTION
    Test helper. Creates a minimal git repository for test isolation.
    Steps:
    1. Create the target directory.
    2. Initialize a new repository, then set test-safe user name and email.
    #>
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

# Commit a file with raw git (no Save-Work — keep this suite independent of
# the command it guards).
function Add-TestCommit {
    <#
    .DESCRIPTION
    Test helper. Writes a file and records it as a saved point in the given repository.
    Steps:
    1. Write the file content to the target path.
    2. Stage all changes and record the saved point with the given message.
    #>
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Message
    )
    Set-Content -LiteralPath (Join-Path $Repo $FileName) -Value $Content -Encoding UTF8
    Push-Location -LiteralPath $Repo
    try {
        Invoke-TestGit -ArgumentList @('add', '-A') | Out-Null
        Invoke-TestGit -ArgumentList @('commit', '-m', $Message) | Out-Null
    }
    finally {
        Pop-Location
    }
}

function Get-TestCurrentBranch {
    <#
    .DESCRIPTION
    Test helper. Returns the active working area name for the given repository.
    Steps:
    1. Query the symbolic reference for the current working area.
    2. Return the first line of output.
    #>
    param([Parameter(Mandatory)][string]$Path)
    Push-Location -LiteralPath $Path
    try {
        $r = Invoke-TestGit -ArgumentList @('symbolic-ref', '--short', 'HEAD') -AllowFailure
        return ($r.Output | Select-Object -First 1)
    }
    finally {
        Pop-Location
    }
}
}

Describe 'Assert-GESafeSave — behavioral contract' {

    BeforeAll {
        Remove-Module GitEasy -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    BeforeEach {
        $script:Stem     = [guid]::NewGuid().ToString('N').Substring(0, 8)
        $script:TempRepo = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_ASS_$script:Stem")

        New-TestRepository -Path $script:TempRepo
        Push-Location -LiteralPath $script:TempRepo
    }

    AfterEach {
        Pop-Location
        Remove-Item -LiteralPath $script:TempRepo -Recurse -Force -ErrorAction SilentlyContinue
    }

    # -----------------------------------------------------------------------
    # Safe workspace — the success path returns the Boolean $true.
    # -----------------------------------------------------------------------
    Context 'Safe workspace' {

        It 'returns $true in a clean repo with a commit' {
            Add-TestCommit -Repo $script:TempRepo -FileName 'README.md' -Content 'base' -Message 'baseline'

            $result = InModuleScope GitEasy { Assert-GESafeSave }

            $result | Should -Be $true
        }

        It 'returns $true when called from a subdirectory of the repo' {
            Add-TestCommit -Repo $script:TempRepo -FileName 'README.md' -Content 'base' -Message 'baseline'
            $sub = Join-Path $script:TempRepo 'src'
            New-Item -Path $sub -ItemType Directory -Force | Out-Null

            Push-Location -LiteralPath $sub
            try {
                $result = InModuleScope GitEasy { Assert-GESafeSave }
            }
            finally {
                Pop-Location
            }

            $result | Should -Be $true
        }

        It 'returns exactly the Boolean $true, not a richer object' {
            Add-TestCommit -Repo $script:TempRepo -FileName 'README.md' -Content 'base' -Message 'baseline'

            $result = InModuleScope GitEasy { Assert-GESafeSave }

            ($result -is [bool]) | Should -Be $true
            $result | Should -Be $true
        }
    }

    # -----------------------------------------------------------------------
    # Not a saveable workspace — Get-GERepoRoot throws OR yields an empty
    # root. Both collapse to the same plain-English message.
    # -----------------------------------------------------------------------
    Context 'Not a saveable workspace' {

        It 'throws a plain-English error when not inside any repository' {
            $nonRepo = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_NR_$([guid]::NewGuid().ToString('N').Substring(0,8))")
            New-Item -Path $nonRepo -ItemType Directory -Force | Out-Null

            $thrown = $null
            Push-Location -LiteralPath $nonRepo
            try {
                try { InModuleScope GitEasy { Assert-GESafeSave } } catch { $thrown = $_ }
            }
            finally {
                Pop-Location
                Remove-Item -LiteralPath $nonRepo -Recurse -Force -ErrorAction SilentlyContinue
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Match 'saveable workspace'
        }

        It 'the not-a-workspace message contains no raw git jargon' {
            $nonRepo = Join-Path ([System.IO.Path]::GetTempPath()) ("GitEasy_NR_$([guid]::NewGuid().ToString('N').Substring(0,8))")
            New-Item -Path $nonRepo -ItemType Directory -Force | Out-Null

            $thrown = $null
            Push-Location -LiteralPath $nonRepo
            try {
                try { InModuleScope GitEasy { Assert-GESafeSave } } catch { $thrown = $_ }
            }
            finally {
                Pop-Location
                Remove-Item -LiteralPath $nonRepo -Recurse -Force -ErrorAction SilentlyContinue
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Not -Match '(?i)\bgit\b'
        }

        It 'throws the workspace message when the repo root resolves empty' {
            $msg = $null
            try {
                InModuleScope GitEasy {
                    Mock Get-GERepoRoot { '   ' }
                    Assert-GESafeSave -Path 'C:\does-not-matter'
                }
            }
            catch { $msg = $_.Exception.Message }

            $msg | Should -Match 'saveable workspace'
        }
    }

    # -----------------------------------------------------------------------
    # Busy repository — a real merge conflict leaves MERGE_HEAD, so the
    # busy check (which runs before the conflict check) fires first.
    # -----------------------------------------------------------------------
    Context 'Busy repository (operation in progress)' {

        It 'throws when a merge is in progress' {
            Add-TestCommit -Repo $script:TempRepo -FileName 'shared.txt' -Content "A`n" -Message 'base'
            $baseBranch = Get-TestCurrentBranch -Path $script:TempRepo

            Invoke-TestGit -ArgumentList @('checkout', '-b', 'feature') | Out-Null
            Add-TestCommit -Repo $script:TempRepo -FileName 'shared.txt' -Content "B`n" -Message 'feature'

            Invoke-TestGit -ArgumentList @('checkout', $baseBranch) | Out-Null
            Add-TestCommit -Repo $script:TempRepo -FileName 'shared.txt' -Content "C`n" -Message 'base2'

            $merge = Invoke-TestGit -ArgumentList @('merge', 'feature') -AllowFailure
            @($merge.Output | Where-Object { $_ -match 'CONFLICT' }).Count -gt 0 | Should -Be $true

            $thrown = $null
            try { InModuleScope GitEasy { Assert-GESafeSave } } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Match 'in progress'
        }

        It 'the busy message contains no raw git jargon' {
            Add-TestCommit -Repo $script:TempRepo -FileName 'shared.txt' -Content "A`n" -Message 'base'
            $baseBranch = Get-TestCurrentBranch -Path $script:TempRepo

            Invoke-TestGit -ArgumentList @('checkout', '-b', 'feature') | Out-Null
            Add-TestCommit -Repo $script:TempRepo -FileName 'shared.txt' -Content "B`n" -Message 'feature'

            Invoke-TestGit -ArgumentList @('checkout', $baseBranch) | Out-Null
            Add-TestCommit -Repo $script:TempRepo -FileName 'shared.txt' -Content "C`n" -Message 'base2'

            Invoke-TestGit -ArgumentList @('merge', 'feature') -AllowFailure | Out-Null

            $thrown = $null
            try { InModuleScope GitEasy { Assert-GESafeSave } } catch { $thrown = $_ }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Not -Match '(?i)\bgit\b'
        }
    }

    # -----------------------------------------------------------------------
    # Unfinished conflicts — isolated from the busy state. Real git cannot
    # produce unmerged paths without an in-progress operation, so the
    # conflict-only branch is reached by mocking the two inner helpers.
    # -----------------------------------------------------------------------
    Context 'Unfinished conflicts (isolated from busy state)' {

        It 'throws and lists the conflicted files when not busy but conflicts exist' {
            $msg = $null
            try {
                InModuleScope GitEasy {
                    Mock Get-GERepoRoot        { 'C:\fake-root' }
                    Mock Test-GERepositoryBusy { [PSCustomObject]@{ IsBusy = $false; Operations = @() } }
                    Mock Get-GEConflictFile   { @('conflicted.txt', 'src/Other.cs') }
                    Assert-GESafeSave -Path 'C:\fake-root'
                }
            }
            catch { $msg = $_.Exception.Message }

            $msg | Should -Match 'unfinished conflicts'
            $msg | Should -Match 'conflicted\.txt'
            $msg | Should -Match 'Other\.cs'
        }

        It 'the conflict message contains no raw git jargon' {
            $msg = $null
            try {
                InModuleScope GitEasy {
                    Mock Get-GERepoRoot        { 'C:\fake-root' }
                    Mock Test-GERepositoryBusy { [PSCustomObject]@{ IsBusy = $false; Operations = @() } }
                    Mock Get-GEConflictFile   { @('conflicted.txt') }
                    Assert-GESafeSave -Path 'C:\fake-root'
                }
            }
            catch { $msg = $_.Exception.Message }

            $msg | Should -Not -BeNullOrEmpty
            $msg | Should -Not -Match '(?i)\bgit\b'
        }
    }
}
