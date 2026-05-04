[CmdletBinding()]
param([string]$ProjectRoot = 'C:\Sysadmin\Scripts\GitEasy')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath $ProjectRoot
Import-Module (Join-Path $ProjectRoot 'GitEasy.psd1') -Force

$commands = @(
    'New-WorkBranch',
    'Switch-Work',
    'Undo-Changes',
    'Restore-File',
    'Clear-Junk'
)

foreach ($command in $commands) {
    $path = Join-Path $ProjectRoot "Public\$command.ps1"
    $content = Get-Content -LiteralPath $path -Raw

    [PSCustomObject]@{
        Command = $command
        Wired   = ($content -notmatch 'not wired yet')
        File    = $path
    }
}
