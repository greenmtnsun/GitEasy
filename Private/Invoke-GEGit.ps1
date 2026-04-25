function Invoke-GEGit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]]$ArgumentList,
        [string]$WorkingDirectory = (Get-Location).Path,
        [switch]$AllowFailure
    )
    $old = Get-Location
    try {
        Set-Location -LiteralPath $WorkingDirectory
        $output = & git @ArgumentList 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        Set-Location -LiteralPath $old
    }
    if (($code -ne 0) -and (-not $AllowFailure)) {
        throw "Git failed: git $($ArgumentList -join ' ')`n$($output -join [Environment]::NewLine)"
    }
    [PSCustomObject]@{ ExitCode = $code; Output = @($output) }
}
