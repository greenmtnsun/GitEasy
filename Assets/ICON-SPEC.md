# GitEasy icon spec

## What goes in this folder

A single PNG file: `Assets/icon.png`. The PowerShell Gallery shows it in
the left sidebar of every package page and uses it as the thumbnail in
search results. The manifest already points at it:

```powershell
IconUri = 'https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/Assets/icon.png'
```

The icon does not exist yet — this folder is staged so the path is
committed and `tools/Publish-GitEasy.ps1` finds the file once it lands.

## Hard requirements

- **Format:** PNG with alpha channel (transparent background).
- **Size:** 85 x 85 pixels. The Gallery renders larger sources at that
  size, but starting at the target resolution avoids resample blur.
- **Direct image URL:** the Gallery does `<img src="$IconUri">`, so the
  URL must serve the raw PNG, not an HTML page. The
  `raw.githubusercontent.com` path above satisfies this.

## Design guidelines

- **Square composition.** The Gallery's thumbnail crop is square.
- **Anti-vibe rule applies.** No stock clip-art, no recolored Git logo
  (trademark hazard), no AI-generated mash-up of every plugin icon
  on the Gallery.
- **Readable at 85 px.** Whatever you draw needs to land at thumbnail
  size. Test by exporting once and looking at it small.
- **No text-heavy logos.** "GitEasy" written out reads as a smudge at
  85 px. A monogram glyph (e.g., a stylized "GE", or an open notebook
  with a fork-branch arrow) reads better.

## Two paths to create it

### Path 1 — Canva (you already have the account)

1. Open Canva, **Create a design > Custom size > 85 x 85 px**.
2. Design the glyph. Keep the background transparent
   (don't add a fill rectangle).
3. **Share > Download**. File type **PNG**. Tick **Transparent
   background**. Click **Download**.
4. Rename the file to `icon.png` and drop it in this folder.

### Path 2 — quick placeholder if Canva is not available

Generate an 85 x 85 transparent PNG with white "GE" text from
PowerShell. Not a beautiful icon, but ships valid metadata so a real
icon can land later. Reusable script:

```powershell
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 85, 85
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear([System.Drawing.Color]::Transparent)
$font = New-Object System.Drawing.Font 'Segoe UI', 36, ([System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 33, 99, 49))
$g.DrawString('GE', $font, $brush, 4, 12)
$bmp.Save("$PSScriptRoot\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
```

## How to verify before publish

```powershell
# 1. File is in place at the expected path.
Test-Path .\Assets\icon.png

# 2. Image is 85x85 PNG.
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Resolve-Path .\Assets\icon.png))
"$($img.Width)x$($img.Height) $($img.RawFormat)"
$img.Dispose()

# 3. Once committed + pushed to main, the IconUri must respond 200.
Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/greenmtnsun/GitEasy/main/Assets/icon.png' `
  -Method Head -UseBasicParsing
```

`tools/Publish-GitEasy.ps1` runs check 3 automatically as part of its
network-reachability pass before publishing.

## What happens if you publish without the icon

The Gallery package page works, but the sidebar shows a generic "no
icon" silhouette. That is the brand-quality signal Keith does not want.
Don't publish without `icon.png` reachable at the IconUri.
