# Public-Save-Work

## Summary

Source file: `Public\Save-Work.ps1`

## Classification

| Field | Value |
| --- | --- |
| Area | Public |
| Source file | `Public\Save-Work.ps1` |
| File name | `Save-Work.ps1` |

## Functions

| Function | Start Line | End Line | Parameters |
| --- | ---: | ---: | --- |
| Save-Work | 1 | 112 | Message, NoPush |
| Invoke-GEGitCommand | 12 | 44 | ArgumentList |

## Source

```powershell
function Save-Work {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message = 'Save work',

        [Parameter()]
        [switch]$NoPush
    )

    function Invoke-GEGitCommand {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string[]]$ArgumentList
        )

        $StandardOutputFile = [System.IO.Path]::GetTempFileName()
        $StandardErrorFile = [System.IO.Path]::GetTempFileName()

        try {
            $Process = Start-Process -FilePath 'git.exe' -ArgumentList $ArgumentList -NoNewWindow -Wait -PassThru -RedirectStandardOutput $StandardOutputFile -RedirectStandardError $StandardErrorFile

            $OutputLines = @()

            if (Test-Path -LiteralPath $StandardOutputFile -PathType Leaf) {
                $OutputLines += @(Get-Content -LiteralPath $StandardOutputFile -ErrorAction SilentlyContinue)
            }

            if (Test-Path -LiteralPath $StandardErrorFile -PathType Leaf) {
                $OutputLines += @(Get-Content -LiteralPath $StandardErrorFile -ErrorAction SilentlyContinue)
            }

            [PSCustomObject]@{
                ExitCode = $Process.ExitCode
                Output   = $OutputLines
            }
        }
        finally {
            Remove-Item -LiteralPath $StandardOutputFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $StandardErrorFile -Force -ErrorAction SilentlyContinue
        }
    }

    $null = Assert-GESafeSave

    $StatusResult = Invoke-GEGitCommand -ArgumentList @('status', '--porcelain')

    if ($StatusResult.ExitCode -ne 0) {
        throw 'Unable to read git status. ' + ($StatusResult.Output -join ' ')
    }

    if ($StatusResult.Output.Count -eq 0) {
        Write-Host 'No changes to save.'
        return
    }

    $AddResult = Invoke-GEGitCommand -ArgumentList @('add', '--all')

    foreach ($Line in $AddResult.Output) {
        Write-Host $Line
    }

    if ($AddResult.ExitCode -ne 0) {
        throw 'git add failed. ' + ($AddResult.Output -join ' ')
    }

    $CommitMessageFile = Join-Path ([System.IO.Path]::GetTempPath()) ('GitEasyCommitMessage_' + [guid]::NewGuid().ToString() + '.txt')

    try {
        [System.IO.File]::WriteAllText($CommitMessageFile, $Message, [System.Text.UTF8Encoding]::new($false))

        $CommitResult = Invoke-GEGitCommand -ArgumentList @('commit', '-F', $CommitMessageFile)

        foreach ($Line in $CommitResult.Output) {
            Write-Host $Line
        }

        if ($CommitResult.ExitCode -ne 0) {
            throw 'git commit failed. ' + ($CommitResult.Output -join ' ')
        }
    }
    finally {
        Remove-Item -LiteralPath $CommitMessageFile -Force -ErrorAction SilentlyContinue
    }

    $BranchResult = Invoke-GEGitCommand -ArgumentList @('branch', '--show-current')

    if ($BranchResult.ExitCode -ne 0 -or $BranchResult.Output.Count -eq 0) {
        throw 'Unable to determine current branch. ' + ($BranchResult.Output -join ' ')
    }

    $BranchName = $BranchResult.Output[0]

    Write-Host "Saved work on branch $BranchName."

    if ($NoPush) {
        Write-Host 'NoPush requested. Skipping push.'
        return
    }

    $PushResult = Invoke-GEGitCommand -ArgumentList @('push')

    foreach ($Line in $PushResult.Output) {
        Write-Host $Line
    }

    if ($PushResult.ExitCode -ne 0) {
        throw 'git push failed. ' + ($PushResult.Output -join ' ')
    }
}

```

## Related Pages

- [[Home]]
- [[Public-Commands]]
- [[Private-Helpers]]
- [[Generated-Page-Index]]
