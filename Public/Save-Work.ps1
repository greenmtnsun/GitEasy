function Save-Work {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)] [string]$Message,
        [switch]$NoPush,
        [switch]$SetUpstream
    )
    $state = Assert-GESafeSave -NoPush:$NoPush -SetUpstream:$SetUpstream
    if ($state.Status.IsClean) {
        Write-Host 'Nothing to save. Working tree is clean.'
        return
    }
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "Save work $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
    }
    if (-not $PSCmdlet.ShouldProcess($state.Root, 'Save work')) { return }
    Invoke-GEGit -ArgumentList @('add', '-A') -WorkingDirectory $state.Root | Out-Null
    Invoke-GEGit -ArgumentList @('commit', '-m', $Message) -WorkingDirectory $state.Root | Out-Null
    if (-not $NoPush) {
        if ([string]::IsNullOrWhiteSpace($state.Upstream)) {
            Invoke-GEGit -ArgumentList @('push', '-u', 'origin', $state.Branch) -WorkingDirectory $state.Root | Out-Null
        }
        else {
            Invoke-GEGit -ArgumentList @('push') -WorkingDirectory $state.Root | Out-Null
        }
    }
    Write-Host "Saved work on branch $($state.Branch)."
}
