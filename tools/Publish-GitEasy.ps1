<#
.SYNOPSIS
Stage GitEasy for a PowerShell Gallery publish.

.DESCRIPTION
Copies only the user-facing files into a temp staging folder, validates
the manifest, runs the Pester suite, optionally checks remote URIs
(LicenseUri, ProjectUri, IconUri), and prints what would be published.
With -Publish + -NuGetApiKey, actually calls Publish-Module.

This is the only sanctioned way to publish GitEasy. A bare
Publish-Module against the repo root would pull in Tests/, tools/,
internal docs, .claude/, and .git/ - none of which belong on the
Gallery.

The inclusion list is enumerate-then-include (safe by default). Anything
not explicitly listed is left out of the .nupkg.

.PARAMETER Version
Override the version label. Default: read from GitEasy.psd1.

.PARAMETER StagePath
Where to stage. Default: $env:TEMP\GitEasy-publish-stage-<version>.

.PARAMETER SkipTests
Skip the Pester run. Use only if you have just run the full suite
yourself. NOT recommended for a real publish.

.PARAMETER SkipNetworkChecks
Skip HEAD requests against LicenseUri / ProjectUri / IconUri. Use on
an air-gapped machine.

.PARAMETER Publish
Actually call Publish-Module. Default: report only (dry run).

.PARAMETER NuGetApiKey
PSGallery API key as a SecureString. Required when -Publish is set.

.EXAMPLE
# Default - stage, validate, and report only. No publish.
.\tools\Publish-GitEasy.ps1

.EXAMPLE
# Real publish.
.\tools\Publish-GitEasy.ps1 -Publish -NuGetApiKey (Read-Host -AsSecureString -Prompt 'PSGallery API key')
#>

[CmdletBinding()]
param(
    [string]       $Version,
    [string]       $StagePath,
    [switch]       $SkipTests,
    [switch]       $SkipNetworkChecks,
    [switch]       $Publish,
    [SecureString] $NuGetApiKey
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repo 'GitEasy.psd1'

# --- read manifest ---
$manifest = Test-ModuleManifest -Path $manifestPath
if (-not $Version) { $Version = $manifest.Version.ToString() }
Write-Host "==> Module : $($manifest.Name) $Version" -ForegroundColor Cyan

# --- guard against publishing a version that is already on the Gallery ---
if ($Publish) {
    $existing = Find-Module -Name GitEasy -RequiredVersion $Version -ErrorAction SilentlyContinue
    if ($existing) {
        throw "PSGallery already has GitEasy $Version. Bump ModuleVersion before publishing."
    }
}

# --- stage path ---
if (-not $StagePath) {
    $StagePath = Join-Path $env:TEMP "GitEasy-publish-stage-$Version"
}
if (Test-Path $StagePath) {
    Write-Host "==> Clearing prior stage at $StagePath" -ForegroundColor DarkGray
    Remove-Item -Recurse -Force $StagePath
}
$stageModule = Join-Path $StagePath 'GitEasy'
New-Item -ItemType Directory -Path $stageModule -Force | Out-Null
Write-Host "==> Staging at $stageModule" -ForegroundColor Cyan

# --- inclusion list (enumerate-then-include) ---
$includeFiles = @(
    'GitEasy.psd1'
    'GitEasy.psm1'
    'LICENSE'
    'README.md'
    'CHANGELOG.md'
)
$includeDirs = @(
    'Public'
    'Private'
    'Format'
    'Assets'
)
$includeDocs = @(
    'docs\HOW-TO-USE-GITEASY.md'
    'docs\QUICKSTART.md'
    'docs\COMMAND_EXAMPLES.md'
    'docs\GITEASY-VS-RAW-GIT.md'
)

foreach ($f in $includeFiles) {
    $src = Join-Path $repo $f
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $stageModule -Force
    } else {
        Write-Warning "Expected file missing: $f"
    }
}
foreach ($d in $includeDirs) {
    $src = Join-Path $repo $d
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $stageModule -Recurse -Force
    } else {
        Write-Warning "Expected dir missing: $d"
    }
}
$stageDocs = Join-Path $stageModule 'docs'
New-Item -ItemType Directory -Path $stageDocs -Force | Out-Null
foreach ($d in $includeDocs) {
    $src = Join-Path $repo $d
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $stageDocs -Force
    } else {
        Write-Warning "Expected doc missing: $d"
    }
}
$imagesSrc = Join-Path $repo 'docs\images'
if (Test-Path $imagesSrc) {
    Copy-Item -Path $imagesSrc -Destination $stageDocs -Recurse -Force
}

# --- verify staged manifest ---
Write-Host "==> Test-ModuleManifest on staged manifest..." -ForegroundColor Cyan
$stagedManifest = Test-ModuleManifest -Path (Join-Path $stageModule 'GitEasy.psd1')
Write-Host "    OK  $($stagedManifest.Name) $($stagedManifest.Version)" -ForegroundColor Green

# --- import the staged module and confirm function count ---
Write-Host "==> Importing staged module..." -ForegroundColor Cyan
Import-Module (Join-Path $stageModule 'GitEasy.psd1') -Force -ErrorAction Stop
$cmds = Get-Command -Module GitEasy
$expected = $stagedManifest.ExportedFunctions.Count
if ($cmds.Count -ne $expected) {
    throw "Expected $expected exported commands, got $($cmds.Count). Check FunctionsToExport vs Public\."
}
Write-Host "    OK  $($cmds.Count) commands exported" -ForegroundColor Green
Remove-Module GitEasy -Force

# --- run Pester ---
if (-not $SkipTests) {
    Write-Host "==> Running Pester suite..." -ForegroundColor Cyan
    Push-Location $repo
    try {
        $pesterResult = Invoke-Pester -Path .\Tests -PassThru -Show None
        if ($pesterResult.FailedCount -gt 0) {
            throw "Pester suite has $($pesterResult.FailedCount) failures. Fix before publishing."
        }
        Write-Host "    OK  $($pesterResult.PassedCount) / $($pesterResult.TotalCount) tests passed" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

# --- network reachability for the three sidebar URIs ---
if (-not $SkipNetworkChecks) {
    Write-Host "==> Verifying remote URIs reachable..." -ForegroundColor Cyan
    $uris = [ordered]@{
        'ProjectUri' = $stagedManifest.PrivateData.PSData.ProjectUri
        'LicenseUri' = $stagedManifest.PrivateData.PSData.LicenseUri
        'IconUri'    = $stagedManifest.PrivateData.PSData.IconUri
    }
    foreach ($name in $uris.Keys) {
        $u = $uris[$name]
        try {
            $r = Invoke-WebRequest -Uri $u -Method Head -UseBasicParsing -MaximumRedirection 5 -ErrorAction Stop
            $ct = $r.Headers['Content-Type']
            Write-Host "    OK  $name -> $u  (HTTP $($r.StatusCode), $ct)" -ForegroundColor Green
        } catch {
            if ($name -eq 'IconUri') {
                Write-Warning "    IconUri not yet reachable ($u). Drop Assets\icon.png into the repo and push to main BEFORE publishing, or the Gallery thumbnail will be broken."
            } else {
                Write-Warning "    $name -> $u  $($_.Exception.Message)"
            }
        }
    }
}

# --- summarize what would ship ---
Write-Host "==> Staged contents:" -ForegroundColor Cyan
$total = 0
$staged = Get-ChildItem -Path $stageModule -Recurse -File
foreach ($f in $staged) {
    $rel = $f.FullName.Substring($stageModule.Length + 1)
    Write-Host ("    {0,-55} {1,8:N1} KB" -f $rel, ($f.Length / 1KB))
    $total += $f.Length
}
Write-Host ("    --- total: {0:N1} KB across {1} files" -f ($total / 1KB), $staged.Count) -ForegroundColor Cyan

# --- publish or report only ---
if ($Publish) {
    if (-not $NuGetApiKey) {
        throw "-Publish requires -NuGetApiKey (a SecureString)."
    }
    $plainKey = [System.Net.NetworkCredential]::new('', $NuGetApiKey).Password
    Write-Host "==> Publish-Module (real)" -ForegroundColor Yellow
    Publish-Module -Path $stageModule -NuGetApiKey $plainKey
    Write-Host "==> Verifying with Find-Module (Gallery indexing can take up to 15 min)..." -ForegroundColor Cyan
    $found = Find-Module -Name GitEasy -RequiredVersion $Version -ErrorAction SilentlyContinue
    if ($found) {
        Write-Host "    OK  Published. Open https://www.powershellgallery.com/packages/GitEasy/$Version" -ForegroundColor Green
    } else {
        Write-Warning "    Find-Module did not see $Version yet. Re-check in a few minutes at https://www.powershellgallery.com/packages/GitEasy/$Version"
    }
} else {
    Write-Host "==> Dry run only. To actually publish, re-run with:" -ForegroundColor Yellow
    Write-Host "    .\tools\Publish-GitEasy.ps1 -Publish -NuGetApiKey (Read-Host -AsSecureString -Prompt 'PSGallery API key')" -ForegroundColor Yellow
}

Write-Host "==> Done." -ForegroundColor Cyan
