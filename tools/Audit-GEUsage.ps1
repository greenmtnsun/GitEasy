<#
.SYNOPSIS
Audit which GitEasy commands the repo's own scripts actually use.

.DESCRIPTION
Audit-GEUsage.ps1 walks the repo's consumer-style scripts (Examples\,
tools\, repo-root *.ps1 by default) and uses the PowerShell AST parser
to find every CommandAst invocation. It then filters those invocations
to the public command names exported by GitEasy.psd1 and reports two
things:

1. USED commands - how many times each is called and from which files.
2. UNUSED commands - exported but never referenced outside the module's
   own Public\, Private\, and Tests\ folders.

The script does not modify any files; it produces a report. Tests\ is
excluded by default because Pester tests reference every command
extensively, which would mask the real signal (which commands does the
project actually demo to users / call from maintainer scripts).

The audit answers two questions for release-prep:
- Are we exporting commands we forgot to demo? (Examples\ gap.)
- Is the public surface still earning its keep? (No external caller.)

A follow-up Pester test (Tests\GitEasy.SurfaceCoverage.Tests.ps1) can
enforce the rule "every exported command must appear in at least one
script under Examples\" - the parsing logic is the same; only the
gate behavior differs.

.PARAMETER ProjectRoot
Absolute path to the GitEasy source repository. Defaults to
C:\Sysadmin\Scripts\GitEasy.

.PARAMETER ScanPath
One or more folders (relative to ProjectRoot) to walk for consumer
scripts. Defaults to @('Examples', 'tools') plus every *.ps1 at the
repo root. Pass an empty array to scan only the repo root.

.PARAMETER IncludeTests
Include Tests\ in the scan. Off by default. Useful as a sanity check
that the Pester suite touches every command at least once.

.EXAMPLE
.\tools\Audit-GEUsage.ps1

Default scan (Examples + tools + repo root, excludes Tests).

.EXAMPLE
.\tools\Audit-GEUsage.ps1 -IncludeTests

Include Tests\ - shows which commands have at least one Pester test
file invocation.

.EXAMPLE
.\tools\Audit-GEUsage.ps1 | Where-Object CallCount -eq 0

Pipe form: returns one PSCustomObject per exported command, so you
can pipe to Where-Object to find the unused set programmatically.

.NOTES
Companion to docs\PSGALLERY-METADATA-PLAYBOOK.md "Pre-publish
checklist". Run before a release to confirm the public surface is
demoed.

Uses [System.Management.Automation.Language.Parser] - the same AST
engine the existing manifest tests use - so there is no external
module dependency.
#>

[CmdletBinding()]
param(
    [string]   $ProjectRoot = 'C:\Sysadmin\Scripts\GitEasy',
    [string[]] $ScanPath    = @('Examples', 'tools'),
    [switch]   $IncludeTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# STATE CHECK
Write-Host ''
Write-Host 'STATE CHECK: GitEasy command-usage audit' -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "Missing project folder: $ProjectRoot"
}

$manifestPath = Join-Path $ProjectRoot 'GitEasy.psd1'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Missing manifest: $manifestPath"
}

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$geCommands = @($manifest.FunctionsToExport | Sort-Object)

if ($geCommands.Count -eq 0) {
    throw "Manifest exports no functions - nothing to audit."
}

Write-Host "Manifest          : $manifestPath"
Write-Host "Exported commands : $($geCommands.Count)"

# Resolve scan files
$consumerFiles = @()
foreach ($rel in $ScanPath) {
    $abs = Join-Path $ProjectRoot $rel
    if (Test-Path -LiteralPath $abs -PathType Container) {
        $consumerFiles += @(Get-ChildItem -LiteralPath $abs -Filter '*.ps1' -Recurse -File)
    }
}
$consumerFiles += @(Get-ChildItem -LiteralPath $ProjectRoot -Filter '*.ps1' -File)
if ($IncludeTests) {
    $testsPath = Join-Path $ProjectRoot 'Tests'
    if (Test-Path -LiteralPath $testsPath -PathType Container) {
        $consumerFiles += @(Get-ChildItem -LiteralPath $testsPath -Filter '*.ps1' -Recurse -File)
    }
}
$consumerFiles = @($consumerFiles | Sort-Object FullName -Unique)

if ($consumerFiles.Count -eq 0) {
    throw "No .ps1 files found in any scan path."
}

Write-Host "Scanned files     : $($consumerFiles.Count)"
Write-Host ''

# AST sweep
$usage = [ordered]@{}
foreach ($c in $geCommands) { $usage[$c] = [System.Collections.Generic.List[string]]::new() }

foreach ($f in $consumerFiles) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$parseErrors)
    if (@($parseErrors).Count -gt 0) {
        Write-Warning "Skipping (parse errors): $($f.FullName)"
        continue
    }
    $cmdNodes = $ast.FindAll({
        param($n) $n -is [System.Management.Automation.Language.CommandAst]
    }, $true)
    foreach ($cn in $cmdNodes) {
        $name = $cn.GetCommandName()
        if ($name -and $usage.Contains($name)) {
            $rel = $f.FullName.Substring($ProjectRoot.Length + 1)
            $usage[$name].Add($rel)
        }
    }
}

# Build result objects
$results = foreach ($name in $geCommands) {
    $calls = $usage[$name]
    [pscustomobject]@{
        Name      = $name
        CallCount = $calls.Count
        FileCount = @($calls | Sort-Object -Unique).Count
        Files     = @($calls | Sort-Object -Unique)
    }
}

# Console summary
$used   = @($results | Where-Object CallCount -gt 0 | Sort-Object @{e='CallCount';desc=$true}, Name)
$unused = @($results | Where-Object CallCount -eq 0 | Sort-Object Name)

Write-Host ("USED   ({0,2} of {1}):" -f $used.Count, $geCommands.Count) -ForegroundColor Green
foreach ($u in $used) {
    Write-Host ("  {0,-18} {1,3} call{2}  across {3} file{4}" -f `
        $u.Name, $u.CallCount, $(if ($u.CallCount -eq 1) {' '} else {'s'}),
        $u.FileCount, $(if ($u.FileCount -eq 1) {' '} else {'s'}))
    foreach ($file in $u.Files) { Write-Host "      $file" -ForegroundColor DarkGray }
}
Write-Host ''
Write-Host ("UNUSED ({0,2} of {1}) - exported but never referenced in the scan:" -f $unused.Count, $geCommands.Count) -ForegroundColor Yellow
foreach ($u in $unused) { Write-Host "  $($u.Name)" }
Write-Host ''
Write-Host ("Coverage: {0} / {1} commands referenced ({2:N1}%)" -f `
    $used.Count, $geCommands.Count, (100 * $used.Count / $geCommands.Count)) -ForegroundColor Cyan

# Emit pipeable results so callers can post-process
$results
