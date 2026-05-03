function Save-Work {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$Message,

        [Parameter()]
        [switch]$NoPush,

        [Parameter()]
        [string]$LogPath = ''
    )

    $repoRoot = $null
    $branch = ''

    try {
        $rootProbe = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -AllowFailure
        if ($rootProbe.ExitCode -eq 0) {
            $repoRoot = $rootProbe.Output | Select-Object -First 1
        }
    }
    catch {
        $repoRoot = $null
    }

    if ($repoRoot) {
        try {
            $branchProbe = Invoke-GEGit -ArgumentList @('symbolic-ref', '--short', 'HEAD') -WorkingDirectory $repoRoot -AllowFailure
            if ($branchProbe.ExitCode -eq 0) {
                $branch = $branchProbe.Output | Select-Object -First 1
            }
        }
        catch {
            $branch = ''
        }
    }

    $session = Start-GELogSession -Command 'Save-Work' -Repository ([string]$repoRoot) -Branch $branch -LogPath $LogPath

    $userMessageOnFailure = 'Could not save your work.'

    try {
        Assert-GESafeSave -Path ([string]$repoRoot) -LogPath $session.Path | Out-Null

        if (-not $repoRoot) {
            $rootResult = Invoke-GEGit -ArgumentList @('rev-parse', '--show-toplevel') -LogPath $session.Path
            $repoRoot = $rootResult.Output | Select-Object -First 1
        }

        if ([string]::IsNullOrWhiteSpace($branch)) {
            $branchResult = Invoke-GEGit -ArgumentList @('symbolic-ref', '--short', 'HEAD') -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
            if ($branchResult.ExitCode -eq 0) {
                $branch = $branchResult.Output | Select-Object -First 1
            }
        }

        if ([string]::IsNullOrWhiteSpace($branch)) {
            throw 'Cannot save right now. No working area is active. Use Switch-Work or New-WorkBranch to start one.'
        }

        $userMessageOnFailure = 'Could not check the workspace state.'

        $statusResult = Invoke-GEGit -ArgumentList @('status', '--porcelain=v1') -WorkingDirectory $repoRoot -LogPath $session.Path
        $statusLines = @($statusResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $isClean = ($statusLines.Count -eq 0)

        $upstreamResult = Invoke-GEGit -ArgumentList @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}') -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
        $hasUpstream = $false
        if ($upstreamResult.ExitCode -eq 0) {
            $upstreamValue = $upstreamResult.Output | Select-Object -First 1
            if (-not [string]::IsNullOrWhiteSpace($upstreamValue)) {
                $hasUpstream = $true
            }
        }

        $remoteResult = Invoke-GEGit -ArgumentList @('remote') -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
        $remotes = @($remoteResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $hasRemote = ($remotes.Count -gt 0)
        $remoteName = ''
        if ($hasRemote) {
            if ($remotes -contains 'origin') {
                $remoteName = 'origin'
            }
            else {
                $remoteName = $remotes[0]
            }
        }

        $aheadCount = 0
        if ($hasRemote) {
            if ($hasUpstream) {
                $aheadResult = Invoke-GEGit -ArgumentList @('rev-list', '--count', '@{u}..HEAD') -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
                if ($aheadResult.ExitCode -eq 0) {
                    $aheadValue = ($aheadResult.Output | Select-Object -First 1) -as [int]
                    if ($null -ne $aheadValue) {
                        $aheadCount = $aheadValue
                    }
                }
            }
            else {
                $unpublishedResult = Invoke-GEGit -ArgumentList @('rev-list', '--count', 'HEAD', '--not', '--remotes') -WorkingDirectory $repoRoot -LogPath $session.Path -AllowFailure
                if ($unpublishedResult.ExitCode -eq 0) {
                    $unpublishedValue = ($unpublishedResult.Output | Select-Object -First 1) -as [int]
                    if ($null -ne $unpublishedValue) {
                        $aheadCount = $unpublishedValue
                    }
                }
            }
        }

        if ($isClean -and $aheadCount -eq 0) {
            Write-Host 'No changes to save.'
        }
        elseif ($isClean -and $aheadCount -gt 0) {
            if ($NoPush) {
                Write-Host "Saved locally only. $aheadCount saved change(s) have not been published."
            }
            elseif (-not $hasRemote) {
                Write-Host 'No published location is configured. Saved locally only.'
            }
            else {
                $userMessageOnFailure = 'Could not publish your saved work.'

                if (-not $PSCmdlet.ShouldProcess($repoRoot, 'Publish saved work')) {
                    Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS' -UserMessage 'Skipped (WhatIf).'
                    return
                }

                if (-not $hasUpstream) {
                    Invoke-GEGit -ArgumentList @('push', '-u', $remoteName, $branch) -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null
                }
                else {
                    Invoke-GEGit -ArgumentList @('push') -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null
                }

                Write-Host "Published $aheadCount saved change(s) to '$branch'."
            }
        }
        else {
            $userMessageOnFailure = 'Could not save your changes.'

            if (-not $PSCmdlet.ShouldProcess($repoRoot, 'Save work')) {
                Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS' -UserMessage 'Skipped (WhatIf).'
                return
            }

            if ([string]::IsNullOrWhiteSpace($Message)) {
                $Message = 'Save work ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }

            Invoke-GEGit -ArgumentList @('add', '--all') -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null

            $messageFile = Join-Path ([System.IO.Path]::GetTempPath()) ('GitEasyCommit_' + [guid]::NewGuid().ToString('N') + '.txt')

            try {
                [System.IO.File]::WriteAllText($messageFile, $Message, [System.Text.UTF8Encoding]::new($false))
                Invoke-GEGit -ArgumentList @('commit', '-F', $messageFile) -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null
            }
            finally {
                Remove-Item -LiteralPath $messageFile -Force -ErrorAction SilentlyContinue
            }

            Write-Host "Saved your work to '$branch'."

            if ($NoPush) {
                Write-Host 'Saved locally only - your work has not been published.'
            }
            elseif (-not $hasRemote) {
                Write-Host 'No published location is configured. Saved locally only.'
            }
            else {
                $userMessageOnFailure = 'Could not publish your saved work.'

                if (-not $hasUpstream) {
                    Invoke-GEGit -ArgumentList @('push', '-u', $remoteName, $branch) -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null
                }
                else {
                    Invoke-GEGit -ArgumentList @('push') -WorkingDirectory $repoRoot -LogPath $session.Path | Out-Null
                }

                Write-Host "Published your work to '$branch'."
            }
        }

        Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
    }
    catch {
        $err = $_

        $innerMessage = $err.Exception.Message
        if ($innerMessage -like 'git *') {
            $finalMsg = $userMessageOnFailure
        }
        else {
            $finalMsg = $innerMessage
        }

        Complete-GELogSession -Path $session.Path -Outcome 'FAILURE' -UserMessage $finalMsg -ErrorMessage $innerMessage

        throw "$finalMsg Details: $($session.Path)"
    }
}
