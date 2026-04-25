[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $ProjectRoot 'GitEasy.psd1'
Import-Module $modulePath -Force
$expected = @(
    'Clear-Junk',
    'Find-CodeChange',
    'Get-VaultStatus',
    'New-WorkBranch',
    'Reset-Login',
    'Restore-File',
    'Save-Work',
    'Set-Ssh',
    'Set-Token',
    'Set-Vault',
    'Show-History',
    'Show-Remote',
    'Switch-Work',
    'Test-Login',
    'Undo-Changes'
)
$actual = @(Get-Command -Module GitEasy | Select-Object -ExpandProperty Name)
$missing = @($expected | Where-Object { $_ -notin $actual })
$extra = @($actual | Where-Object { $_ -notin $expected })
if ($missing.Count -gt 0) { throw "Missing public commands: $($missing -join ', ')" }
if ($extra.Count -gt 0) { throw "Unexpected public commands: $($extra -join ', ')" }
Write-Host 'Manifest test passed.' -ForegroundColor Green
