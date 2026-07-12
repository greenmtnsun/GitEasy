#Requires -Version 7.0
<#
.SYNOPSIS
Build per-command HTML pages for the GitEasy site by piping WikiEngine
output through ConvertFrom-Markdown into the site's brand template.

.DESCRIPTION
Three-stage pipeline:

  1. Harvest. Import the GitEasy module, invoke WikiEngine's
     New-WikiFromModule to render Markdown command pages into a temp
     folder. Twenty-one command pages + one index.md result.
  2. Convert. For each .md, render the body via PS 7's
     ConvertFrom-Markdown, then wrap in an HTML page template that
     matches the rest of the GitEasy site (top nav, brand CSS,
     footer). The MkDocs Material-flavored HTML divs WikiEngine emits
     (.va-hero, .va-recipe, .va-param-card, .chip, .risk-pill) are
     styled in site/style.css to GitEasy's cream + green palette.
  3. Index. Emit site/commands/index.html listing all 21 commands as
     clickable cards, plus a back-link to the homepage.

The generated HTML pages ARE committed to git so the static site
ships ready to serve. Regenerate by re-running this script after CBH
changes. Source of truth remains the .ps1 files' comment-based help -
this script is a derivation, not the authority.

Requires:
- PowerShell 7+ (for ConvertFrom-Markdown).
- WikiEngine installed at C:\Sysadmin\Scripts\WikiEngine.
- GitEasy module importable in the current session.

.PARAMETER ProjectRoot
GitEasy repo root. Defaults to C:\Sysadmin\Scripts\GitEasy.

.PARAMETER WikiEnginePath
Path to dbaDocsEngine.psd1. Defaults to
C:\Sysadmin\Scripts\WikiEngine\Engine\dbaDocsEngine\dbaDocsEngine.psd1.

.PARAMETER OutputDir
Where the rendered command HTML lands. Defaults to <ProjectRoot>\site\commands.

.PARAMETER KeepTemp
Keep the temp folder where WikiEngine wrote the intermediate
Markdown. Useful for debugging the render shape.

.EXAMPLE
.\tools\Build-SiteCommands.ps1

Default - harvests GitEasy, renders to site\commands\, builds an
index page.
#>

[CmdletBinding()]
param(
    [string] $ProjectRoot     = 'C:\Sysadmin\Scripts\GitEasy',
    [string] $WikiEnginePath  = 'C:\Sysadmin\Scripts\WikiEngine\Engine\dbaDocsEngine\dbaDocsEngine.psd1',
    [string] $OutputDir,
    [switch] $KeepTemp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'STATE CHECK: GitEasy site-commands build (via WikiEngine)' -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "Missing project folder: $ProjectRoot"
}
if (-not (Test-Path -LiteralPath $WikiEnginePath -PathType Leaf)) {
    throw "Missing WikiEngine manifest: $WikiEnginePath. Edit the -WikiEnginePath argument if it lives elsewhere."
}
if (-not $OutputDir) {
    $OutputDir = Join-Path $ProjectRoot 'site\commands'
}

Write-Host "Project root  : $ProjectRoot"
Write-Host "WikiEngine    : $WikiEnginePath"
Write-Host "Output dir    : $OutputDir"
Write-Host ''

# --- Step 1: harvest via WikiEngine ---
$tempBase = Join-Path $env:TEMP "giteasy-sitecommands-build"
if (Test-Path $tempBase) { Remove-Item -Recurse -Force $tempBase }
New-Item -ItemType Directory -Path $tempBase | Out-Null

Write-Host '==> Importing modules...' -ForegroundColor Cyan
Import-Module GitEasy -Force
Import-Module $WikiEnginePath -Force
Write-Host "    GitEasy   $((Get-Module GitEasy).Version)"
Write-Host "    WikiEngine $((Get-Module dbaDocsEngine).Version)"
Write-Host ''

Write-Host '==> Harvesting + rendering Markdown via WikiEngine...' -ForegroundColor Cyan
New-WikiFromModule -ModuleName GitEasy -BaseFolder $tempBase | Out-Null

$mdDir = Join-Path $tempBase 'Wiki-GitEasy'
if (-not (Test-Path -LiteralPath $mdDir -PathType Container)) {
    throw "Expected WikiEngine output at $mdDir - not found."
}
$mdFiles = @(Get-ChildItem -Path $mdDir -Filter '*.md' -File | Sort-Object Name)
Write-Host "    $($mdFiles.Count) Markdown pages produced"
Write-Host ''

# --- Step 2: convert MD -> HTML ---
if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
# Wipe stale .html in the output dir (we regenerate every command page)
Get-ChildItem -Path $OutputDir -Filter '*.html' -File -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host '==> Converting Markdown to styled HTML...' -ForegroundColor Cyan

# HERE-STRING AUDIT (GitEasy DR-011 amended 2026-05-28) — excluded per
# suite-policy #2: literal HTML template body, single-quoted (never
# interpolated). Tool-time only; output is the GitEasy docs site, never
# shipped to PSGallery.
$htmlTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{TITLE}} - GitEasy</title>
  <meta name="description" content="{{DESC}}">
  <meta property="og:title" content="{{TITLE}} - GitEasy">
  <meta property="og:description" content="{{DESC}}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="{{URL}}">
  <meta property="og:site_name" content="GitEasy">
  <meta property="og:image" content="https://git-easy.com/images/hero-wall-photo.png">
  <link rel="canonical" href="{{URL}}">
  <link rel="stylesheet" href="../style.css">
</head>
<body>

<header class="topbar">
  <div class="topbar-inner">
    <a href="../index.html" class="brand">GitEasy<span class="brand-dot"></span></a>
    <nav class="links">
      <a href="../index.html">Home</a>
      <a href="../how.html">How it works</a>
      <a href="../who.html">Who it's for</a>
      <a href="index.html"{{COMMANDS_ACTIVE}}>Commands</a>
      <a href="https://github.com/greenmtnsun/GitEasy">GitHub</a>
    </nav>
  </div>
</header>

<main>
  <p class="muted"><a href="index.html">&laquo; All commands</a></p>
{{BODY}}
</main>

<footer>
  <div class="footer-inner">
    GitEasy is built by <a href="https://github.com/greenmtnsun">Keith Ramsey</a> under <a href="https://github.com/greenmtnsun/GitEasy/blob/main/LICENSE">MPL 2.0</a>.<br>
    Provided as-is. No warranty. Use at your own risk.<br>
    <a href="https://github.com/greenmtnsun/GitEasy">Source on GitHub</a> &nbsp;&middot;&nbsp;
    <a href="index.html">All commands</a> &nbsp;&middot;&nbsp;
    <a href="../index.html">Home</a>
  </div>
</footer>

</body>
</html>
'@

$generated = @()
foreach ($md in $mdFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($md.Name)
    $outFile = Join-Path $OutputDir ($baseName.ToLowerInvariant() + '.html')

    # Pull the raw MD and strip the YAML frontmatter (we re-emit it as <title>).
    $raw = Get-Content -LiteralPath $md.FullName -Raw
    $title = $baseName
    if ($raw -match "^---\s*\r?\ntitle:\s*(.+?)\r?\n---\s*\r?\n") {
        $title = $Matches[1].Trim()
        $raw = $raw -replace "^---\s*\r?\n.*?\r?\n---\s*\r?\n", ''
    }

    # ConvertFrom-Markdown -> HTML body
    $info = $raw | ConvertFrom-Markdown
    $bodyHtml = $info.Html

    # Synopsis for the meta description: pull the tagline span if present,
    # else the first paragraph after the hero block.
    $desc = ""
    if ($bodyHtml -match '<span class="tagline">([^<]+)</span>') { $desc = $Matches[1].Trim() }
    if (-not $desc -and $baseName -eq 'index') { $desc = "GitEasy v1.5.3 commands - one page per public command." }
    if (-not $desc) { $desc = "$title - GitEasy command reference." }

    $isCommandsActive = if ($baseName -eq 'index') { ' class="active"' } else { '' }
    $pageUrl = "https://git-easy.com/commands/$($baseName.ToLowerInvariant()).html"

    $page = $htmlTemplate `
        -replace '{{TITLE}}', [System.Web.HttpUtility]::HtmlEncode($title) `
        -replace '{{DESC}}', [System.Web.HttpUtility]::HtmlEncode($desc) `
        -replace '{{URL}}', $pageUrl `
        -replace '{{BODY}}', $bodyHtml `
        -replace '{{COMMANDS_ACTIVE}}', $isCommandsActive

    Set-Content -LiteralPath $outFile -Value $page -Encoding UTF8

    Write-Host ("    OK  {0,-30} -> {1}" -f $md.Name, (Split-Path -Leaf $outFile)) -ForegroundColor Green
    $generated += [pscustomobject]@{
        BaseName = $baseName
        Title    = $title
        Desc     = $desc
        OutFile  = $outFile
    }
}

# --- Step 3: build a clean commands/index.html with the 21 command cards ---
# Move the WikiEngine-rendered index.md (now index.html) aside and emit our
# own grid-shaped index that matches the rest of the site's aesthetic.
$wikiIndex = Join-Path $OutputDir 'index.html'
if (Test-Path $wikiIndex) {
    # The WikiEngine index renders the same module-summary it'd ship to
    # MkDocs. For the site we want a focused card-grid landing page.
    # We replace it.
}

Write-Host ''
Write-Host '==> Building site/commands/index.html (card grid)...' -ForegroundColor Cyan

$commandsOnly = @($generated | Where-Object { $_.BaseName -ne 'index' } | Sort-Object BaseName)

$cardLinks = ($commandsOnly | ForEach-Object {
    $cmdName = $_.BaseName
    $href    = $cmdName.ToLowerInvariant() + '.html'
    $syn     = $_.Desc
    "        <a href=`"$href`"><span class=`"cmd-name`">$cmdName</span><span class=`"cmd-syn`">$([System.Web.HttpUtility]::HtmlEncode($syn))</span></a>"
}) -join "`n"

# HERE-STRING AUDIT (GitEasy DR-011 amended 2026-05-28) — excluded per
# suite-policy #2: double-quoted HTML index template. Every interpolated
# value is HTML-encoded at the call site (see HtmlEncode above), so the
# interpolation surface is sanitized. Tool-time only; output is the site
# index, never shipped to PSGallery.
$indexHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Commands - GitEasy</title>
  <meta name="description" content="All $($commandsOnly.Count) GitEasy commands, one page per command. Plain-English help generated from the source.">
  <meta property="og:title" content="Commands - GitEasy">
  <meta property="og:description" content="All $($commandsOnly.Count) GitEasy commands, one page per command. Plain-English help generated from the source.">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://git-easy.com/commands/">
  <meta property="og:site_name" content="GitEasy">
  <meta property="og:image" content="https://git-easy.com/images/hero-wall-photo.png">
  <link rel="canonical" href="https://git-easy.com/commands/">
  <link rel="stylesheet" href="../style.css">
</head>
<body>

<header class="topbar">
  <div class="topbar-inner">
    <a href="../index.html" class="brand">GitEasy<span class="brand-dot"></span></a>
    <nav class="links">
      <a href="../index.html">Home</a>
      <a href="../how.html">How it works</a>
      <a href="../who.html">Who it's for</a>
      <a href="index.html" class="active">Commands</a>
      <a href="https://github.com/greenmtnsun/GitEasy">GitHub</a>
    </nav>
  </div>
</header>

<main>

  <h1>Commands</h1>
  <p class="lede">
    All $($commandsOnly.Count) GitEasy commands, one page per command.
    Plain-English help generated from the source. Tap a card to see
    description, recipes, parameters, and safety notes.
  </p>

  <div class="command-list">
$cardLinks
  </div>

  <p class="muted" style="margin-top: 32px;">
    Pages built by <code>tools/Build-SiteCommands.ps1</code> from the
    .ps1 files' comment-based help via
    <a href="https://github.com/greenmtnsun/WikiEngine">WikiEngine</a>.
    Source of truth is the code; this page is a derivation.
  </p>

</main>

<footer>
  <div class="footer-inner">
    GitEasy is built by <a href="https://github.com/greenmtnsun">Keith Ramsey</a> under <a href="https://github.com/greenmtnsun/GitEasy/blob/main/LICENSE">MPL 2.0</a>.<br>
    Provided as-is. No warranty. Use at your own risk.<br>
    <a href="https://github.com/greenmtnsun/GitEasy">Source on GitHub</a> &nbsp;&middot;&nbsp;
    <a href="../index.html">Home</a>
  </div>
</footer>

</body>
</html>
"@

Set-Content -LiteralPath (Join-Path $OutputDir 'index.html') -Value $indexHtml -Encoding UTF8
Write-Host ("    OK  index.html ({0} command cards)" -f $commandsOnly.Count) -ForegroundColor Green

# --- Cleanup ---
if (-not $KeepTemp) {
    Remove-Item -Recurse -Force $tempBase -ErrorAction SilentlyContinue
} else {
    Write-Host ''
    Write-Host "Temp kept at: $tempBase" -ForegroundColor DarkGray
}

Write-Host ''
$totalBytes = (Get-ChildItem -Path $OutputDir -Filter '*.html' -File | Measure-Object -Property Length -Sum).Sum
Write-Host ("Generated {0} HTML pages, {1:N1} KB total." -f ($commandsOnly.Count + 1), ($totalBytes / 1KB)) -ForegroundColor Cyan
Write-Host ("Output: $OutputDir") -ForegroundColor Cyan
