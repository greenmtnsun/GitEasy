[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
$manifestPath = Join-Path $ProjectRoot 'GitEasy.psd1'
Import-Module $manifestPath -Force

# Confirm every command the module promises is actually available after import.
# The expected list comes from the manifest itself, so this example never
# goes stale as commands are added or renamed.
$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$expected = @($manifest.FunctionsToExport)

Write-Host "Checking $($expected.Count) GitEasy commands..." -ForegroundColor Cyan

$rows = foreach ($name in $expected) {
    $found = $null -ne (Get-Command -Module GitEasy -Name $name -ErrorAction SilentlyContinue)
    [PSCustomObject]@{
        Command   = $name
        Available = if ($found) { 'Yes' } else { 'No' }
    }
}

$rows | Format-Table -AutoSize | Out-Host

$missing = @($rows | Where-Object { $_.Available -eq 'No' })
if ($missing.Count -eq 0) {
    Write-Host "All commands are installed and ready." -ForegroundColor Green
}
else {
    Write-Host "Missing: $($missing.Command -join ', '). Re-import or reinstall GitEasy." -ForegroundColor Red
}
