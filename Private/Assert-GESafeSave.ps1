function Assert-GESafeSave {
    [CmdletBinding()]
    param(
        [string]$Path = (Get-Location).Path,

        [string]$LogPath = ''
    )

    try {
        $rootResult = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -WorkingDirectory $Path -LogPath $LogPath
    }
    catch {
        throw 'This folder is not inside a saveable workspace. Move into your project folder first.'
    }

    $root = $rootResult.Output | Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($root)) {
        throw 'This folder is not inside a saveable workspace. Move into your project folder first.'
    }

    $gitDirResult = Invoke-GEGit -ArgumentList @('rev-parse', '--git-dir') -WorkingDirectory $root -LogPath $LogPath -AllowFailure

    if ($gitDirResult.ExitCode -eq 0) {
        $gitDir = $gitDirResult.Output | Select-Object -First 1

        if (-not [System.IO.Path]::IsPathRooted($gitDir)) {
            $gitDir = Join-Path $root $gitDir
        }

        $busyChecks = @(
            @{ Name = 'merge';       File = 'MERGE_HEAD' },
            @{ Name = 'cherry-pick'; File = 'CHERRY_PICK_HEAD' },
            @{ Name = 'revert';      File = 'REVERT_HEAD' },
            @{ Name = 'bisect';      File = 'BISECT_START' },
            @{ Name = 'rebase';      File = 'rebase-merge' },
            @{ Name = 'rebase';      File = 'rebase-apply' }
        )

        $foundOps = @()
        foreach ($check in $busyChecks) {
            if (Test-Path -LiteralPath (Join-Path $gitDir $check.File)) {
                $foundOps += $check.Name
            }
        }

        if ($foundOps.Count -gt 0) {
            $opList = (@($foundOps | Select-Object -Unique) -join ', ')
            throw "Cannot save right now. A $opList is in progress. Finish or cancel that first."
        }
    }

    $conflictResult = Invoke-GEGit -ArgumentList @('diff', '--name-only', '--diff-filter=U') -WorkingDirectory $root -LogPath $LogPath -AllowFailure

    if ($conflictResult.ExitCode -ne 0) {
        throw 'Could not check the workspace for conflicts.'
    }

    $conflicts = @($conflictResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ($conflicts.Count -gt 0) {
        $list = ($conflicts -join ', ')
        throw "Cannot save while there are unfinished conflicts. Resolve these files first: $list"
    }

    return $true
}
