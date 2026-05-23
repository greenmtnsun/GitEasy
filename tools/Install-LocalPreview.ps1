<#
.SYNOPSIS
Install the staged GitEasy module to your user-scope PowerShell module
folder so you can see what an Install-Module from PSGallery would look
like - same versioned layout, same payload, including the PDFs.

.DESCRIPTION
Install-LocalPreview.ps1 runs the publish staging (tools\Publish-
GitEasy.ps1, dry-run mode) to assemble exactly what the .nupkg would
contain, then copies the staged folder to the user-scope module path
under a versioned subfolder (the layout Install-Module uses):

  PS 7+ on Windows : $HOME\Documents\PowerShell\Modules\GitEasy\<ver>\
  PS 5.1           : $HOME\Documents\WindowsPowerShell\Modules\GitEasy\<ver>\

After install you can:
  Import-Module GitEasy
  (Get-Module GitEasy).Path                  # see where it loaded from
  explorer (Get-Module GitEasy).ModuleBase   # browse the installed copy

To remove a preview later:
  Remove-Item -Recurse "$HOME\Documents\PowerShell\Modules\GitEasy\<ver>"

This is NOT the same as tools\Install-GitEasy.ps1. That script installs
the runtime essentials system-wide (Program Files, requires admin) and
omits docs / Assets / PDFs. This script installs the FULL Gallery
payload to user-scope so you can preview what consumers will see.

.PARAMETER ProjectRoot
Absolute path to the GitEasy source repository. Defaults to
C:\Sysadmin\Scripts\GitEasy.

.PARAMETER ModulesRoot
Override the destination modules root. Defaults to the user-scope
modules folder for the current PowerShell edition.

.PARAMETER SkipTests
Pass through to Publish-GitEasy.ps1 - skip the Pester gate. Useful when
you just verified the suite and don't want to rerun.

.PARAMETER Force
Overwrite an existing install at the same version path without backup.
By default, an existing same-version folder is renamed to
<path>.bak.<timestamp> before the new copy lands.

.EXAMPLE
.\tools\Install-LocalPreview.ps1

Default - stage with the full Pester gate, copy to your user-scope
versioned module path, verify Import-Module GitEasy loads the new
install.

.EXAMPLE
.\tools\Install-LocalPreview.ps1 -SkipTests

Skip the Pester gate (faster iteration). Use only if you have just
run Pester yourself.

.NOTES
The versioned subfolder layout (...\GitEasy\1.5.3\GitEasy.psd1) is what
Install-Module produces. PowerShell's loader picks the highest available
version across all paths on $env:PSModulePath, so a 1.5.3 user-scope
install will win over any older copy on the machine - including a stale
1.4.2 in Program Files.
#>

[CmdletBinding()]
param(
    [string] $ProjectRoot = 'C:\Sysadmin\Scripts\GitEasy',
    [string] $ModulesRoot,
    [switch] $SkipTests,
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'STATE CHECK: Install GitEasy local preview' -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "Missing project folder: $ProjectRoot"
}

# Resolve the modules root for the current PowerShell edition. Naively
# constructing $HOME\Documents\PowerShell\Modules misses the case where
# Documents is redirected through OneDrive (Microsoft's default on many
# managed Windows installs) - the real user-scope path then lives under
# $env:USERPROFILE\OneDrive\... and is the entry PS actually uses.
# Discover it from $env:PSModulePath instead of constructing it.
if (-not $ModulesRoot) {
    $userScope = ($env:PSModulePath -split [System.IO.Path]::PathSeparator) |
        Where-Object {
            $_ -and (Test-Path -LiteralPath $_ -PathType Container -ErrorAction SilentlyContinue) -and
            ($_ -like "$env:USERPROFILE\*") -and ($_ -notlike "*\Program Files\*")
        } |
        Select-Object -First 1
    if (-not $userScope) {
        # Fall back to the convention if PSModulePath has nothing under $USERPROFILE.
        $editionFolder = if ($PSVersionTable.PSEdition -eq 'Core') { 'PowerShell' } else { 'WindowsPowerShell' }
        $userScope = Join-Path $HOME "Documents\$editionFolder\Modules"
        Write-Warning "No user-scope path on `$env:PSModulePath - falling back to $userScope (may not be auto-loaded)."
    }
    $ModulesRoot = $userScope
}

# Read manifest version
$manifest = Test-ModuleManifest -Path (Join-Path $ProjectRoot 'GitEasy.psd1') -ErrorAction Stop
$version = $manifest.Version.ToString()

Write-Host "Project root  : $ProjectRoot"
Write-Host "Module version: $version"
Write-Host "Modules root  : $ModulesRoot"
Write-Host "Edition       : PowerShell $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
Write-Host ''

# Step 1 - run the publish staging
$publisher = Join-Path $ProjectRoot 'tools\Publish-GitEasy.ps1'
if (-not (Test-Path -LiteralPath $publisher)) {
    throw "Missing publisher script: $publisher"
}

$pubArgs = @{
    SkipNetworkChecks = $true   # local preview, no need to probe PSGallery URIs
}
if ($SkipTests) { $pubArgs.SkipTests = $true }

Write-Host '==> Staging via Publish-GitEasy.ps1 (dry run)...' -ForegroundColor Cyan
& $publisher @pubArgs | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Staging failed (exit $LASTEXITCODE). Run .\tools\Publish-GitEasy.ps1 directly to see the error."
}

# Stage location is deterministic: $env:TEMP\GitEasy-publish-stage-<version>\GitEasy
$stagePath = Join-Path $env:TEMP "GitEasy-publish-stage-$version\GitEasy"
if (-not (Test-Path -LiteralPath $stagePath -PathType Container)) {
    throw "Expected staged folder not found at $stagePath. Did the publisher run cleanly?"
}

# Step 2 - resolve target versioned path
$installBase = Join-Path $ModulesRoot 'GitEasy'
$targetPath = Join-Path $installBase $version

if (-not (Test-Path -LiteralPath $ModulesRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $ModulesRoot -Force | Out-Null
}

# Step 3 - handle existing install at the same version
if (Test-Path -LiteralPath $targetPath -PathType Container) {
    if ($Force) {
        Remove-Item -Recurse -Force $targetPath
        Write-Host "Cleared prior install at $targetPath" -ForegroundColor DarkGray
    } else {
        $stamp = (Get-Date).ToString('yyyyMMddHHmmss')
        $backup = "$targetPath.bak.$stamp"
        Rename-Item -LiteralPath $targetPath -NewName (Split-Path -Leaf $backup) -Force
        Write-Host "Backed up prior install -> $backup" -ForegroundColor DarkGray
    }
}

# Step 4 - copy
Write-Host "==> Copying staged folder to $targetPath" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
Copy-Item -Path (Join-Path $stagePath '*') -Destination $targetPath -Recurse -Force

# Step 5 - verify via Get-Module -ListAvailable in the CURRENT edition's
# session. Shelling out to powershell.exe (PS 5.1) would only see the
# WindowsPowerShell\Modules paths and miss a PS 7 user-scope install.
Write-Host '==> Verifying install...' -ForegroundColor Cyan
$available = @(Get-Module GitEasy -ListAvailable | Sort-Object Version -Descending)
$found = $available | Select-Object -First 1
if (-not $found) {
    Write-Warning "    Get-Module -ListAvailable found no GitEasy. The freshly-installed path may not be on `$env:PSModulePath in this session."
} elseif ([string]$found.Version -eq $version -and $found.ModuleBase -like "$targetPath*") {
    Write-Host "    OK  PowerShell loader picks $($found.Version) from $($found.ModuleBase)" -ForegroundColor Green
} else {
    Write-Warning "    Loader picks $($found.Version) from $($found.ModuleBase) - your fresh install may be shadowed by another copy."
}

# Report ALL available copies so the user can see any conflicts
if ($available.Count -gt 1) {
    Write-Host ''
    Write-Host '    All GitEasy copies visible to this edition:' -ForegroundColor DarkGray
    foreach ($m in $available) {
        $marker = if ($m.ModuleBase -like "$targetPath*") { '<- fresh install' } else { '' }
        Write-Host ("      {0,-8} {1} {2}" -f $m.Version, $m.ModuleBase, $marker) -ForegroundColor DarkGray
    }
}

# Step 6 - report what landed
$installed = Get-ChildItem -Path $targetPath -Recurse -File
Write-Host ''
Write-Host "Installed GitEasy $version" -ForegroundColor Green
Write-Host ("  Path : $targetPath")
Write-Host ("  Files: {0} ({1:N1} KB)" -f $installed.Count, (($installed | Measure-Object Length -Sum).Sum / 1KB))
Write-Host ''
Write-Host 'Try it now:' -ForegroundColor Cyan
Write-Host '  Import-Module GitEasy'
Write-Host '  Get-Command -Module GitEasy'
Write-Host '  (Get-Module GitEasy).Path'
Write-Host "  explorer '$targetPath'"
Write-Host ''
Write-Host 'To remove this preview install later:' -ForegroundColor DarkGray
Write-Host "  Remove-Item -Recurse '$targetPath'"
