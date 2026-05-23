#Requires -Version 7.0
<#
.SYNOPSIS
Generate per-doc PDFs from the user-facing Markdown sources.

.DESCRIPTION
Build-DocsPdf.ps1 turns the user-facing Markdown docs into PDF files,
one PDF per Markdown source. The pipeline is fully Windows-native:
PowerShell 7's built-in ConvertFrom-Markdown renders Markdown to HTML
body, the script wraps that body in a styled HTML page (clean
typography, single brand-green accent, restrained), and Microsoft Edge
in headless mode prints the HTML to PDF via --print-to-pdf.

No pandoc, no LaTeX, no Python dependency. The toolchain is whatever
ships with Windows 10+ (Edge) and a recent PowerShell (7+).

Called automatically by tools/Publish-GitEasy.ps1 against the staged
docs folder before the .nupkg contents are listed - PDFs are derived
artifacts and live in the package, not in the source tree.

Can also be run standalone against the source-tree docs (the PDFs
land alongside the .md files); useful for local preview.

.PARAMETER ProjectRoot
Absolute path to the GitEasy source repository. Defaults to
C:\Sysadmin\Scripts\GitEasy.

.PARAMETER OutputDir
Where the generated PDFs land. Defaults to <ProjectRoot>\docs.

.PARAMETER Docs
Relative paths (under ProjectRoot) of the Markdown files to render.
Defaults to the five user-facing docs: HOW-TO, QUICKSTART,
COMMAND_EXAMPLES, GITEASY-VS-RAW-GIT, FOR-GIT-EXPERTS.

.PARAMETER BrowserPath
Override the auto-detected browser. Useful for custom Chrome / Edge
installs. Defaults to msedge.exe at its standard install path, falling
back to chrome.exe.

.EXAMPLE
.\tools\Build-DocsPdf.ps1

Generate PDFs for all five user-facing docs, landing in docs\*.pdf.

.EXAMPLE
.\tools\Build-DocsPdf.ps1 -OutputDir C:\Temp\GitEasyPdfs

Generate PDFs to a custom output directory (the publish script does
this with the staged docs folder as target).

.NOTES
PowerShell 7+ required (ConvertFrom-Markdown was added in PS 6).
Image references in the Markdown are resolved relative to the
generated temp HTML's location, so the temp file lives in the same
folder as the source Markdown during render to keep image links
intact.
#>

[CmdletBinding()]
param(
    [string]   $ProjectRoot = 'C:\Sysadmin\Scripts\GitEasy',
    [string]   $OutputDir,
    [string[]] $Docs = @(
        'docs\HOW-TO-USE-GITEASY.md'
        'docs\QUICKSTART.md'
        'docs\COMMAND_EXAMPLES.md'
        'docs\GITEASY-VS-RAW-GIT.md'
        'docs\FOR-GIT-EXPERTS.md'
    ),
    [string]   $BrowserPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'STATE CHECK: GitEasy doc-to-PDF build' -ForegroundColor Cyan

# Sanity
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "Missing project folder: $ProjectRoot"
}
if (-not $OutputDir) { $OutputDir = Join-Path $ProjectRoot 'docs' }
if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Locate the browser
if (-not $BrowserPath) {
    $candidates = @(
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    )
    $BrowserPath = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $BrowserPath -or -not (Test-Path -LiteralPath $BrowserPath)) {
    throw "Edge or Chrome not found. Set -BrowserPath explicitly or install Microsoft Edge."
}
Write-Host "Browser     : $BrowserPath"
Write-Host "Output dir  : $OutputDir"
Write-Host "Source docs : $($Docs.Count)"
Write-Host ''

# Embedded CSS. Restrained typography, single brand-green accent,
# generous line-height and whitespace. Tuned for printed/PDF reading.
$css = @'
@page {
  size: Letter;
  margin: 0.85in 0.75in;
}
body {
  font-family: -apple-system, "Segoe UI", "Helvetica Neue", Arial, sans-serif;
  font-size: 11pt;
  line-height: 1.55;
  color: #111827;
  max-width: 6.75in;
  margin: 0 auto;
  padding: 0;
}
h1 {
  font-size: 24pt;
  font-weight: 700;
  border-bottom: 3px solid #166534;
  padding-bottom: 0.18em;
  margin: 1.6em 0 0.6em;
}
h1:first-child { margin-top: 0; }
h2 {
  font-size: 16pt;
  font-weight: 700;
  border-bottom: 1px solid #d1d5db;
  padding-bottom: 0.12em;
  margin: 1.6em 0 0.5em;
  color: #166534;
}
h3 {
  font-size: 13pt;
  font-weight: 600;
  margin: 1.3em 0 0.4em;
}
h4 {
  font-size: 11.5pt;
  font-weight: 600;
  margin: 1.1em 0 0.3em;
  color: #374151;
}
p { margin: 0.6em 0; }
ul, ol { margin: 0.6em 0; padding-left: 1.4em; }
li { margin: 0.18em 0; }
code {
  font-family: "Cascadia Mono", Consolas, "Courier New", monospace;
  font-size: 10pt;
  background-color: #f3f4f6;
  padding: 0.12em 0.35em;
  border-radius: 3px;
  color: #111827;
}
pre {
  background-color: #f9fafb;
  border: 1px solid #e5e7eb;
  border-left: 3px solid #166534;
  border-radius: 4px;
  padding: 0.7em 0.9em;
  overflow-x: auto;
  page-break-inside: avoid;
}
pre code {
  background: none;
  padding: 0;
  font-size: 9.5pt;
  line-height: 1.45;
}
blockquote {
  border-left: 3px solid #d1d5db;
  padding: 0.1em 0.9em;
  margin: 0.7em 0;
  color: #4b5563;
  font-style: normal;
}
table {
  border-collapse: collapse;
  width: 100%;
  margin: 0.7em 0;
  page-break-inside: avoid;
  font-size: 10pt;
}
th {
  text-align: left;
  border-bottom: 2px solid #166534;
  padding: 0.4em 0.6em;
  background-color: #f9fafb;
}
td {
  border-bottom: 1px solid #e5e7eb;
  padding: 0.35em 0.6em;
  vertical-align: top;
}
a { color: #166534; text-decoration: none; border-bottom: 1px dotted #166534; }
img { max-width: 100%; height: auto; page-break-inside: avoid; }
hr { border: none; border-top: 1px solid #e5e7eb; margin: 1.5em 0; }
strong { font-weight: 600; }
'@

$generated = @()
foreach ($rel in $Docs) {
    $mdPath = Join-Path $ProjectRoot $rel
    if (-not (Test-Path -LiteralPath $mdPath -PathType Leaf)) {
        Write-Warning "Missing source doc, skipping: $rel"
        continue
    }
    $base = [System.IO.Path]::GetFileNameWithoutExtension($mdPath)
    $sourceDir = Split-Path -Parent $mdPath
    $tmpHtml = Join-Path $sourceDir "$base.tmp.html"
    $pdfOut = Join-Path $OutputDir "$base.pdf"

    Write-Host "Rendering   $rel" -ForegroundColor Cyan

    # Markdown -> HTML body
    $info = ConvertFrom-Markdown -Path $mdPath
    $bodyHtml = $info.Html

    # Wrap in a styled standalone HTML page. Title is the first H1 if
    # ConvertFrom-Markdown exposed one, falling back to the basename.
    $title = $base
    if ($info.Tokens -and $info.Tokens.Count -gt 0) {
        $firstHeading = $info.Tokens | Where-Object { $_.GetType().Name -eq 'HeadingBlock' -and $_.Level -eq 1 } | Select-Object -First 1
        if ($firstHeading) { $title = $firstHeading.Inline.ToString() }
    }
    $page = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>$([System.Web.HttpUtility]::HtmlEncode($title))</title>
  <style>
$css
  </style>
</head>
<body>
$bodyHtml
</body>
</html>
"@

    # Write the temp HTML next to the source so relative image refs resolve
    Set-Content -LiteralPath $tmpHtml -Value $page -Encoding UTF8

    # Edge headless print to PDF
    $tmpHtmlUri = ([System.Uri]((Resolve-Path $tmpHtml).Path)).AbsoluteUri
    $browserArgs = @(
        '--headless=new'
        '--disable-gpu'
        '--no-pdf-header-footer'
        "--print-to-pdf=$pdfOut"
        $tmpHtmlUri
    )
    $proc = Start-Process -FilePath $BrowserPath -ArgumentList $browserArgs -Wait -PassThru -WindowStyle Hidden
    if ($proc.ExitCode -ne 0) {
        Write-Warning "  Browser exited $($proc.ExitCode) on $rel - PDF may be missing or incomplete."
    }

    # Clean temp HTML
    Remove-Item -LiteralPath $tmpHtml -Force -ErrorAction SilentlyContinue

    if (Test-Path -LiteralPath $pdfOut) {
        $size = (Get-Item $pdfOut).Length
        Write-Host ("  OK  {0,-30} {1,8:N1} KB" -f "$base.pdf", ($size / 1KB)) -ForegroundColor Green
        $generated += [pscustomobject]@{
            Source = $rel
            Pdf    = $pdfOut
            Bytes  = $size
        }
    } else {
        Write-Warning "  PDF not produced: $pdfOut"
    }
}

Write-Host ''
$totalBytes = if ($generated.Count -gt 0) { ($generated | Measure-Object -Property Bytes -Sum).Sum } else { 0 }
Write-Host ("Generated {0} PDF{1}, total {2:N1} KB" -f `
    $generated.Count, $(if ($generated.Count -eq 1) {''} else {'s'}),
    ($totalBytes / 1KB)) -ForegroundColor Cyan

# Emit pipeable results
$generated
