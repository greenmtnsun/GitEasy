<#
.SYNOPSIS
    Creates GitHub Wiki-compatible Markdown pages for the GitEasy PowerShell module.

.DESCRIPTION
    Scans the local GitEasy module source tree and writes Markdown files that can be copied
    directly into a GitHub Wiki repository.

    Default input:
        C:\Sysadmin\Scripts\GitEasyV2

    Default output:
        C:\Sysadmin\Scripts\GitEasyV2\Wiki

    This script is intentionally atomic:
    - Performs a state check before writing output.
    - Does not use $PSScriptRoot.
    - Does not require GitHub CLI.
    - Does not modify the GitEasy code except for creating/replacing the Wiki output folder.
    - Produces GitHub Wiki-compatible .md files.

.NOTES
    Designed for the GitEasy project.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GitEasyRoot = 'C:\Sysadmin\Scripts\GitEasyV2',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = 'C:\Sysadmin\Scripts\GitEasyV2\Wiki',

    [Parameter()]
    [switch]$IncludeSource = $true,

    [Parameter()]
    [switch]$Overwrite
)

$ErrorActionPreference = 'Stop'

function ConvertTo-GitEasyWikiFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )

    $Name = $Title.Trim()
    $Name = $Name -replace '[\\/:*?"<>|#%{}~&]', '-'
    $Name = $Name -replace '\s+', '-'
    $Name = $Name -replace '-+', '-'
    $Name = $Name.Trim('-')

    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw 'Cannot create wiki file name from empty title.'
    }

    return "$Name.md"
}

function Get-GitEasyFunctionInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [ValidateSet('Public','Private','Root','Test','Tool','Other')]
        [string]$Area,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GitEasyRoot
    )

    $Tokens = $null
    $ParseErrors = $null
    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$Tokens, [ref]$ParseErrors)

    $RelativePath = $FilePath.Substring($GitEasyRoot.Length).TrimStart('\')

    $Functions = @(
        $Ast.FindAll(
            {
                param($Node)
                $Node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            },
            $true
        )
    )

    if ($Functions.Count -eq 0) {
        [PSCustomObject]@{
            Name          = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
            Area          = $Area
            FilePath      = $FilePath
            RelativePath  = $RelativePath
            Synopsis      = ''
            Description   = ''
            Parameters    = @()
            ParseErrors   = @($ParseErrors)
            HasFunction   = $false
            Source        = Get-Content -LiteralPath $FilePath -Raw
            StartLine     = 1
            EndLine       = (Get-Content -LiteralPath $FilePath).Count
        }

        return
    }

    foreach ($Function in $Functions) {
        $CommandAst = $Function.Body.ParamBlock
        $Parameters = @()

        if ($CommandAst -and $CommandAst.Parameters) {
            foreach ($Parameter in $CommandAst.Parameters) {
                $ParameterName = $Parameter.Name.VariablePath.UserPath
                $TypeName = ''
                if ($Parameter.StaticType) {
                    $TypeName = $Parameter.StaticType.Name
                }

                $Parameters += [PSCustomObject]@{
                    Name = $ParameterName
                    Type = $TypeName
                }
            }
        }

        $Help = @{
            Synopsis = ''
            Description = ''
        }

        $ExtentText = $Function.Extent.Text
        $PriorText = (Get-Content -LiteralPath $FilePath -Raw).Substring(0, $Function.Extent.StartOffset)

        $HelpBlockMatches = [regex]::Matches($PriorText, '(?s)<#(.*?)#>')
        if ($HelpBlockMatches.Count -gt 0) {
            $LastHelpBlock = $HelpBlockMatches[$HelpBlockMatches.Count - 1].Groups[1].Value

            $SynopsisMatch = [regex]::Match($LastHelpBlock, '(?is)\.SYNOPSIS\s+(.*?)(\.[A-Z]+|\z)')
            if ($SynopsisMatch.Success) {
                $Help.Synopsis = ($SynopsisMatch.Groups[1].Value -replace '\s+', ' ').Trim()
            }

            $DescriptionMatch = [regex]::Match($LastHelpBlock, '(?is)\.DESCRIPTION\s+(.*?)(\.[A-Z]+|\z)')
            if ($DescriptionMatch.Success) {
                $Help.Description = ($DescriptionMatch.Groups[1].Value -replace '\s+', ' ').Trim()
            }
        }

        [PSCustomObject]@{
            Name          = $Function.Name
            Area          = $Area
            FilePath      = $FilePath
            RelativePath  = $RelativePath
            Synopsis      = $Help.Synopsis
            Description   = $Help.Description
            Parameters    = $Parameters
            ParseErrors   = @($ParseErrors)
            HasFunction   = $true
            Source        = $ExtentText
            StartLine     = $Function.Extent.StartLineNumber
            EndLine       = $Function.Extent.EndLineNumber
        }
    }
}

function New-GitEasyMarkdownTable {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object[]]$Rows,

        [Parameter(Mandatory)]
        [string[]]$Columns
    )

    $Lines = New-Object System.Collections.Generic.List[string]

    $Lines.Add('| ' + ($Columns -join ' | ') + ' |')
    $Lines.Add('| ' + (($Columns | ForEach-Object { '---' }) -join ' | ') + ' |')

    foreach ($Row in @($Rows)) {
        $Values = foreach ($Column in $Columns) {
            $Value = $Row.$Column
            if ($null -eq $Value) {
                ''
            }
            else {
                (($Value.ToString()) -replace '\|', '\|' -replace "`r?`n", '<br>')
            }
        }

        $Lines.Add('| ' + ($Values -join ' | ') + ' |')
    }

    return $Lines.ToArray()
}

function Write-GitEasyMarkdownFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    $Parent = Split-Path -Path $Path -Parent

    if (-not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -Path $Parent -ItemType Directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllLines(
        $Path,
        $Lines,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function New-GitEasyFunctionWikiPage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$FunctionInfo,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter()]
        [switch]$IncludeSource
    )

    $Title = $FunctionInfo.Name
    $FileName = ConvertTo-GitEasyWikiFileName -Title $Title
    $Path = Join-Path $OutputPath $FileName

    $Lines = New-Object System.Collections.Generic.List[string]

    $Lines.Add("# $Title")
    $Lines.Add('')
    $Lines.Add('## Summary')
    $Lines.Add('')

    if ([string]::IsNullOrWhiteSpace($FunctionInfo.Synopsis)) {
        if ($FunctionInfo.Area -eq 'Public') {
            $Lines.Add("`$Title` is a public GitEasy command.")
        }
        elseif ($FunctionInfo.Area -eq 'Private') {
            $Lines.Add("`$Title` is an internal GitEasy helper.")
        }
        else {
            $Lines.Add("`$Title` is part of the GitEasy codebase.")
        }
    }
    else {
        $Lines.Add($FunctionInfo.Synopsis)
    }

    $Lines.Add('')
    $Lines.Add('## Classification')
    $Lines.Add('')
    $Lines.Add("| Field | Value |")
    $Lines.Add("| --- | --- |")
    $Lines.Add("| Area | $($FunctionInfo.Area) |")
    $Lines.Add("| Source file | `$($FunctionInfo.RelativePath)` |")
    $Lines.Add("| Lines | $($FunctionInfo.StartLine)-$($FunctionInfo.EndLine) |")
    $Lines.Add("| Public API | $([bool]($FunctionInfo.Area -eq 'Public')) |")
    $Lines.Add('')

    if (-not [string]::IsNullOrWhiteSpace($FunctionInfo.Description)) {
        $Lines.Add('## Description')
        $Lines.Add('')
        $Lines.Add($FunctionInfo.Description)
        $Lines.Add('')
    }

    $Lines.Add('## Parameters')
    $Lines.Add('')

    if ($FunctionInfo.Parameters.Count -eq 0) {
        $Lines.Add('This function declares no parameters.')
    }
    else {
        $Rows = foreach ($Parameter in $FunctionInfo.Parameters) {
            [PSCustomObject]@{
                Name = $Parameter.Name
                Type = $Parameter.Type
            }
        }

        foreach ($Line in (New-GitEasyMarkdownTable -Rows $Rows -Columns @('Name','Type'))) {
            $Lines.Add($Line)
        }
    }

    $Lines.Add('')
    $Lines.Add('## Usage Notes')
    $Lines.Add('')

    if ($FunctionInfo.Area -eq 'Public') {
        $Lines.Add('- This is part of the supported GitEasy command surface.')
        $Lines.Add('- Prefer this command over raw Git when working in a GitEasy-managed workflow.')
        $Lines.Add('- Use `Find-CodeChange` before saving when you want a quick repository state check.')
    }
    else {
        $Lines.Add('- This is internal implementation detail.')
        $Lines.Add('- Private helpers should keep the `GE` prefix where possible.')
        $Lines.Add('- Do not treat this as public API unless it is intentionally exported later.')
    }

    if ($FunctionInfo.ParseErrors.Count -gt 0) {
        $Lines.Add('')
        $Lines.Add('## Parse Warnings')
        $Lines.Add('')
        foreach ($ParseError in $FunctionInfo.ParseErrors) {
            $Lines.Add("- Line $($ParseError.Extent.StartLineNumber): $($ParseError.Message)")
        }
    }

    if ($IncludeSource) {
        $Lines.Add('')
        $Lines.Add('## Source')
        $Lines.Add('')
        $Lines.Add('```powershell')
        foreach ($SourceLine in ($FunctionInfo.Source -split "`r?`n")) {
            $Lines.Add($SourceLine)
        }
        $Lines.Add('```')
    }

    $Lines.Add('')
    $Lines.Add('## Related Pages')
    $Lines.Add('')
    $Lines.Add('- [[Home]]')
    $Lines.Add('- [[Public Commands]]')
    $Lines.Add('- [[Private Helpers]]')
    $Lines.Add('- [[Architecture]]')

    Write-GitEasyMarkdownFile -Path $Path -Lines $Lines.ToArray()

    return [PSCustomObject]@{
        Name = $Title
        Area = $FunctionInfo.Area
        Path = $Path
        WikiFile = $FileName
        RelativePath = $FunctionInfo.RelativePath
    }
}

Write-Host 'STATE CHECK: Create GitEasy GitHub Wiki files'

if (-not (Test-Path -LiteralPath $GitEasyRoot -PathType Container)) {
    throw "Missing GitEasy root: $GitEasyRoot"
}

if (-not (Test-Path -LiteralPath "$GitEasyRoot\.git" -PathType Container)) {
    throw "Missing Git repository: $GitEasyRoot\.git"
}

if (-not (Test-Path -LiteralPath "$GitEasyRoot\GitEasy.psd1" -PathType Leaf)) {
    throw "Missing GitEasy manifest: $GitEasyRoot\GitEasy.psd1"
}

if (-not (Test-Path -LiteralPath "$GitEasyRoot\GitEasy.psm1" -PathType Leaf)) {
    throw "Missing GitEasy root module: $GitEasyRoot\GitEasy.psm1"
}

if ((Test-Path -LiteralPath $OutputPath -PathType Container) -and -not $Overwrite) {
    throw "Output path already exists. Rerun with -Overwrite to replace it: $OutputPath"
}

if (Test-Path -LiteralPath $OutputPath -PathType Container) {
    Remove-Item -LiteralPath $OutputPath -Recurse -Force
}

New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

$SourceFiles = New-Object System.Collections.Generic.List[object]

$AreaRoots = @(
    [PSCustomObject]@{ Area = 'Public';  Path = Join-Path $GitEasyRoot 'Public'  },
    [PSCustomObject]@{ Area = 'Private'; Path = Join-Path $GitEasyRoot 'Private' },
    [PSCustomObject]@{ Area = 'Test';    Path = Join-Path $GitEasyRoot 'Tests'   },
    [PSCustomObject]@{ Area = 'Tool';    Path = Join-Path $GitEasyRoot 'Tools'   }
)

foreach ($AreaRoot in $AreaRoots) {
    if (Test-Path -LiteralPath $AreaRoot.Path -PathType Container) {
        Get-ChildItem -LiteralPath $AreaRoot.Path -Recurse -File -Include '*.ps1','*.psm1','*.psd1' |
            ForEach-Object {
                $SourceFiles.Add([PSCustomObject]@{
                    Area = $AreaRoot.Area
                    Path = $_.FullName
                })
            }
    }
}

$RootFiles = @(
    Join-Path $GitEasyRoot 'GitEasy.psm1',
    Join-Path $GitEasyRoot 'GitEasy.psd1'
)

foreach ($RootFile in $RootFiles) {
    if (Test-Path -LiteralPath $RootFile -PathType Leaf) {
        $SourceFiles.Add([PSCustomObject]@{
            Area = 'Root'
            Path = $RootFile
        })
    }
}

if ($SourceFiles.Count -eq 0) {
    throw 'No PowerShell source files found to document.'
}

$FunctionInfos = New-Object System.Collections.Generic.List[object]

foreach ($SourceFile in $SourceFiles) {
    $Infos = @(Get-GitEasyFunctionInfo -FilePath $SourceFile.Path -Area $SourceFile.Area -GitEasyRoot $GitEasyRoot)
    foreach ($Info in $Infos) {
        $FunctionInfos.Add($Info)
    }
}

$GeneratedPages = New-Object System.Collections.Generic.List[object]

foreach ($FunctionInfo in ($FunctionInfos | Sort-Object Area, Name, RelativePath)) {
    $Page = New-GitEasyFunctionWikiPage -FunctionInfo $FunctionInfo -OutputPath $OutputPath -IncludeSource:$IncludeSource
    $GeneratedPages.Add($Page)
}

$PublicPages = @($GeneratedPages | Where-Object Area -eq 'Public' | Sort-Object Name)
$PrivatePages = @($GeneratedPages | Where-Object Area -eq 'Private' | Sort-Object Name)
$TestPages = @($GeneratedPages | Where-Object Area -eq 'Test' | Sort-Object Name)
$ToolPages = @($GeneratedPages | Where-Object Area -eq 'Tool' | Sort-Object Name)
$RootPages = @($GeneratedPages | Where-Object Area -eq 'Root' | Sort-Object Name)

$HomeLines = New-Object System.Collections.Generic.List[string]
$HomeLines.Add('# GitEasy Wiki')
$HomeLines.Add('')
$HomeLines.Add('GitEasy is a PowerShell-first Git helper module designed to keep Git workflows plain-English, safe, and repeatable.')
$HomeLines.Add('')
$HomeLines.Add('## Project Goals')
$HomeLines.Add('')
$HomeLines.Add('- Preserve the classic GitEasy command surface.')
$HomeLines.Add('- Prefer simple GitEasy commands before raw Git commands.')
$HomeLines.Add('- Fail fast on unsafe repository states.')
$HomeLines.Add('- Support GitHub and GitLab workflows.')
$HomeLines.Add('- Keep private helpers behind the supported public API.')
$HomeLines.Add('')
$HomeLines.Add('## Main Pages')
$HomeLines.Add('')
$HomeLines.Add('- [[Public Commands]]')
$HomeLines.Add('- [[Private Helpers]]')
$HomeLines.Add('- [[Architecture]]')
$HomeLines.Add('- [[Troubleshooting]]')
$HomeLines.Add('- [[Known Bugs and Fixes]]')
$HomeLines.Add('- [[Roadmap]]')
$HomeLines.Add('- [[Generated Page Index]]')
$HomeLines.Add('')
$HomeLines.Add('## Public Commands')
$HomeLines.Add('')
if ($PublicPages.Count -eq 0) {
    $HomeLines.Add('No public command pages were generated.')
}
else {
    foreach ($Page in $PublicPages) {
        $PageTitle = [System.IO.Path]::GetFileNameWithoutExtension($Page.WikiFile)
        $HomeLines.Add("- [[$PageTitle]]")
    }
}
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath 'Home.md') -Lines $HomeLines.ToArray()

$PublicLines = New-Object System.Collections.Generic.List[string]
$PublicLines.Add('# Public Commands')
$PublicLines.Add('')
$PublicLines.Add('These pages document the supported GitEasy command surface.')
$PublicLines.Add('')
foreach ($Line in (New-GitEasyMarkdownTable -Rows $PublicPages -Columns @('Name','RelativePath','WikiFile'))) {
    $PublicLines.Add($Line)
}
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath 'Public-Commands.md') -Lines $PublicLines.ToArray()

$PrivateLines = New-Object System.Collections.Generic.List[string]
$PrivateLines.Add('# Private Helpers')
$PrivateLines.Add('')
$PrivateLines.Add('These pages document internal GitEasy implementation helpers. These are not the public API.')
$PrivateLines.Add('')
foreach ($Line in (New-GitEasyMarkdownTable -Rows $PrivatePages -Columns @('Name','RelativePath','WikiFile'))) {
    $PrivateLines.Add($Line)
}
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath 'Private-Helpers.md') -Lines $PrivateLines.ToArray()

$IndexLines = New-Object System.Collections.Generic.List[string]
$IndexLines.Add('# Generated Page Index')
$IndexLines.Add('')
$IndexLines.Add("Generated from: `$GitEasyRoot`")
$IndexLines.Add("Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$IndexLines.Add('')
foreach ($Line in (New-GitEasyMarkdownTable -Rows ($GeneratedPages | Sort-Object Area, Name) -Columns @('Area','Name','RelativePath','WikiFile'))) {
    $IndexLines.Add($Line)
}
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath 'Generated-Page-Index.md') -Lines $IndexLines.ToArray()

$ArchitectureLines = @(
    '# Architecture',
    '',
    'GitEasy is organized around a small public command surface with private helper functions underneath.',
    '',
    '## Source Layout',
    '',
    '| Path | Purpose |',
    '| --- | --- |',
    '| `GitEasy.psd1` | Module manifest. |',
    '| `GitEasy.psm1` | Root module loader. |',
    '| `Public\` | Supported user-facing commands. |',
    '| `Private\` | Internal helpers and Git engine logic. |',
    '| `Tests\` | Pester tests. |',
    '| `Tools\` | Project tooling scripts, if present. |',
    '',
    '## Design Rules',
    '',
    '- Public commands should stay plain-English and stable.',
    '- Private helpers should use the `GE` prefix.',
    '- GitEasy should fail fast on ambiguous or unsafe repository states.',
    '- GitEasy should decide native Git success by exit code, not by stderr text alone.',
    '- Generated files should avoid UTF-8 BOM unless explicitly required.',
    '- Scripts should use explicit paths in project automation instead of relying on `$PSScriptRoot`.',
    '',
    '## Save-Work Flow',
    '',
    'Typical `Save-Work` behavior:',
    '',
    '1. Verify the current directory is a Git repository.',
    '2. Check for real unresolved merge conflicts.',
    '3. Stage changes.',
    '4. Commit with the supplied message.',
    '5. Push unless `-NoPush` is specified.',
    '',
    '## Related Pages',
    '',
    '- [[Home]]',
    '- [[Public Commands]]',
    '- [[Private Helpers]]'
)
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath 'Architecture.md') -Lines $ArchitectureLines

$TroubleshootingLines = @(
    '# Troubleshooting',
    '',
    '## LF/CRLF warnings are not merge conflicts',
    '',
    'Git may print warnings like:',
    '',
    '```text',
    'LF will be replaced by CRLF the next time Git touches it',
    '```',
    '',
    'These warnings are not unresolved merge conflicts. A real conflict check should use:',
    '',
    '```powershell',
    'git diff --name-only --diff-filter=U',
    '```',
    '',
    '## Native Git can write normal progress to stderr',
    '',
    'PowerShell can treat native command stderr as an error when `$ErrorActionPreference = ''Stop''`.',
    '',
    'GitEasy should judge Git success using process exit codes.',
    '',
    '## Commit message BOM pollution',
    '',
    'Avoid writing Git commit message temp files with UTF-8 BOM. Use:',
    '',
    '```powershell',
    '[System.IO.File]::WriteAllText($CommitMessageFile, $Message, [System.Text.UTF8Encoding]::new($false))',
    '```',
    '',
    '## Branch clean but ahead of origin',
    '',
    'A clean working tree does not always mean everything is published. Check:',
    '',
    '```powershell',
    'git status -sb',
    '```',
    '',
    'If it shows `[ahead N]`, pending commits still need to be pushed.',
    '',
    '## Related Pages',
    '',
    '- [[Known Bugs and Fixes]]',
    '- [[Architecture]]'
)
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath 'Troubleshooting.md') -Lines $TroubleshootingLines

$KnownBugLines = @(
    '# Known Bugs and Fixes',
    '',
    'This page tracks bugs discovered while using GitEasy to publish DBCCPROJECT and GitEasy itself.',
    '',
    '## Fixed',
    '',
    '### False conflict detection from LF/CRLF warnings',
    '',
    'GitEasy previously treated Git line-ending warnings as unresolved merge conflicts.',
    '',
    'Correct check:',
    '',
    '```powershell',
    'git diff --name-only --diff-filter=U',
    '```',
    '',
    '### Save-Work missing NoPush support',
    '',
    '`Save-Work` now supports `-NoPush` so a commit can be created without immediately pushing.',
    '',
    '### Native Git stderr caused false failures',
    '',
    'Git can write normal progress output to stderr. GitEasy should use process exit code as the success/failure signal.',
    '',
    '### Commit message UTF-8 BOM pollution',
    '',
    'Commit message temp files should be written with UTF-8 without BOM.',
    '',
    '## Open',
    '',
    '### Clean branch ahead of upstream',
    '',
    '`Save-Work` should push when the working tree is clean but the current branch is ahead of its upstream.',
    '',
    'Suggested check:',
    '',
    '```powershell',
    'git rev-list --count @{upstream}..HEAD',
    '```',
    '',
    '### Refactor native Git runner',
    '',
    'Move any embedded Git command runner out of `Public\Save-Work.ps1` and into a private helper such as:',
    '',
    '```text',
    'Private\Invoke-GEGitCommand.ps1',
    '```'
)
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath 'Known-Bugs-and-Fixes.md') -Lines $KnownBugLines

$RoadmapLines = @(
    '# Roadmap',
    '',
    '## Near Term',
    '',
    '- Add Pester tests for `Save-Work` and `Assert-GESafeSave`.',
    '- Add clean-but-ahead push behavior to `Save-Work`.',
    '- Move native Git execution into a private GE-prefixed helper.',
    '- Keep `.bak` files ignored.',
    '',
    '## Test Coverage Needed',
    '',
    '- LF/CRLF warnings are not conflicts.',
    '- Real unresolved merge conflicts block save.',
    '- `Save-Work -NoPush` commits without pushing.',
    '- Native Git stderr does not falsely fail GitEasy.',
    '- Commit messages are UTF-8 without BOM.',
    '- Clean-but-ahead branches are pushed.',
    '',
    '## Longer Term',
    '',
    '- Confirm GitLab support flows.',
    '- Harden token and SSH setup workflows.',
    '- Keep public commands stable and plain-English.'
)
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath 'Roadmap.md') -Lines $RoadmapLines

$SidebarLines = New-Object System.Collections.Generic.List[string]
$SidebarLines.Add('# GitEasy')
$SidebarLines.Add('')
$SidebarLines.Add('- [[Home]]')
$SidebarLines.Add('- [[Public Commands]]')
$SidebarLines.Add('- [[Private Helpers]]')
$SidebarLines.Add('- [[Architecture]]')
$SidebarLines.Add('- [[Troubleshooting]]')
$SidebarLines.Add('- [[Known Bugs and Fixes]]')
$SidebarLines.Add('- [[Roadmap]]')
$SidebarLines.Add('- [[Generated Page Index]]')
$SidebarLines.Add('')
$SidebarLines.Add('## Commands')
foreach ($Page in $PublicPages) {
    $PageTitle = [System.IO.Path]::GetFileNameWithoutExtension($Page.WikiFile)
    $SidebarLines.Add("- [[$PageTitle]]")
}
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath '_Sidebar.md') -Lines $SidebarLines.ToArray()

$FooterLines = @(
    'Generated from the local GitEasy source tree.',
    '',
    'GitEasy-first workflow: prefer GitEasy commands before raw Git commands.'
)
Write-GitEasyMarkdownFile -Path (Join-Path $OutputPath '_Footer.md') -Lines $FooterLines

$Summary = [PSCustomObject]@{
    GitEasyRoot        = $GitEasyRoot
    OutputPath         = $OutputPath
    SourceFileCount    = $SourceFiles.Count
    FunctionPageCount  = $GeneratedPages.Count
    PublicPageCount    = $PublicPages.Count
    PrivatePageCount   = $PrivatePages.Count
    TestPageCount      = $TestPages.Count
    ToolPageCount      = $ToolPages.Count
    RootPageCount      = $RootPages.Count
}

$SummaryPath = Join-Path $OutputPath 'wiki-generation-summary.json'
[System.IO.File]::WriteAllText($SummaryPath, ($Summary | ConvertTo-Json -Depth 4), [System.Text.UTF8Encoding]::new($false))

Write-Host 'GitEasy wiki files generated.'
$Summary | Format-List

Write-Host ''
Write-Host 'Next GitEasy-first publish step:'
Write-Host "Set-Location '$GitEasyRoot'"
Write-Host "Find-CodeChange"
Write-Host "Save-Work -Message 'Add generated GitEasy wiki files'"
