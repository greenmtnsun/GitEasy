# =============================================================================
# Script  : Get-DiffTriggeredChecks.ps1
# Author  : Keith Ramsey
# Created : 2026-11-17
# =============================================================================
# Change Log
# -----------------------------------------------------------------------------
# 2026-11-17  Keith Ramsey  Initial creation. Step 4 of the verify skill. Reads
#                            the staged diff of a repo and prints each
#                            pattern-library entry whose `trigger:` regex
#                            matches an added line or a changed file's path, so
#                            a commit runs only the checks its diff calls for.
#                            Taken from the Claude Code team's diff-triggered
#                            reliability checklist (their 39 items, 3 to 10 run
#                            per change). Informational: always exits 0 once
#                            the repo is found.
# =============================================================================

<#
.SYNOPSIS
Lists the pattern-library entries whose trigger matches the change about to be committed.

.DESCRIPTION
Each pattern file under the patterns folder may carry a line `trigger: '<regex>'` in its
frontmatter, or `trigger: none` when the pattern cannot be seen in a diff. This script collects the
added lines of the repo's staged diff, plus one `FILE: <path>` line per changed file, and tests every
trigger against them. A match means that pattern's check applies to this commit.

Steps:
  1. Resolve the repo root from -RepoPath with git. Stop with an error when it is not a git repo.
  2. Collect the diff: the index by default, the working tree too with -IncludeUnstaged, or the
     tree against -Ref when one is given. Zero context lines, so only changed lines are read.
  3. Turn the diff into scan lines: `FILE: <path>` for each changed file, then each added line
     with its leading plus removed.
  4. Read every *.md in the patterns folder and take the first `trigger:` line in its first 40
     lines, quotes stripped. Skip `none` and files with no trigger, counting both.
  5. Test each trigger against each scan line. Keep up to three matching lines per pattern.
  6. Write one object per matched pattern (Pattern, PatternPath, Trigger, Matches) and a one-line
     summary to the host. Exit 0.

.PARAMETER RepoPath
A path inside the git repo to check. Defaults to the current directory.

.PARAMETER PatternsDir
The folder holding the pattern files. Defaults to the meta memory's patterns folder.

.PARAMETER Ref
Compare the working tree against this ref (for example HEAD~1) instead of reading the index.

.PARAMETER IncludeUnstaged
Also read unstaged changes to tracked files.

.EXAMPLE
pwsh -NoProfile -File C:\Users\keith\.claude\skills\verify\Get-DiffTriggeredChecks.ps1 -RepoPath C:\Sysadmin\Scripts\GitEasy
Lists the patterns whose triggers match GitEasy's staged changes.
#>
[CmdletBinding()]
param(
    [string] $RepoPath = (Get-Location).Path,
    [string] $PatternsDir = 'C:\Users\keith\.claude\projects\C--Users-keith\memory\patterns',
    [string] $Ref,
    [switch] $IncludeUnstaged
)

$ErrorActionPreference = 'Stop'

# 1. Repo root.
$root = & git -C $RepoPath rev-parse --show-toplevel 2>$null
if (-not $root) {
    Write-Error "Not a git repository: $RepoPath"
    exit 1
}

# 2. Diff text.
$diffLines = @()
if ($Ref) {
    $diffLines += @(& git -C $root diff -U0 $Ref 2>$null)
} else {
    $diffLines += @(& git -C $root diff --cached -U0 2>$null)
    if ($IncludeUnstaged) { $diffLines += @(& git -C $root diff -U0 2>$null) }
}

# 3. Scan lines.
$scan = New-Object System.Collections.Generic.List[string]
foreach ($line in $diffLines) {
    if ($null -eq $line) { continue }
    if ($line -match '^\+\+\+ b/(.+)$') { $scan.Add('FILE: ' + $Matches[1]); continue }
    if ($line -match '^\+\+\+ ') { continue }
    if ($line -match '^\+(.*)$') { $scan.Add($Matches[1]) }
}

# 4. Triggers.
if (-not (Test-Path -LiteralPath $PatternsDir)) {
    Write-Error "Patterns folder not found: $PatternsDir"
    exit 1
}
$patterns = @()
$noTrigger = 0
$noneTrigger = 0
foreach ($file in Get-ChildItem -LiteralPath $PatternsDir -Filter '*.md' -File) {
    $head = @(Get-Content -LiteralPath $file.FullName -TotalCount 40)
    $trigger = $null
    foreach ($h in $head) {
        if ($h -match '^\s*trigger:\s*(.+?)\s*$') { $trigger = $Matches[1]; break }
    }
    if (-not $trigger) { $noTrigger++; continue }
    if ($trigger -match '^(["''])(.*)\1$') { $trigger = $Matches[2] }
    if ($trigger -match '^(?i)none\b') { $noneTrigger++; continue }
    $patterns += [pscustomobject]@{ Pattern = $file.BaseName; PatternPath = $file.FullName; Trigger = $trigger }
}

# 5. Match.
$matched = @()
foreach ($p in $patterns) {
    $hits = New-Object System.Collections.Generic.List[string]
    try {
        foreach ($s in $scan) {
            if ($s -match $p.Trigger) {
                $hits.Add($s)
                if ($hits.Count -ge 3) { break }
            }
        }
    } catch {
        Write-Warning ("Pattern {0}: trigger did not compile as a regex ({1})" -f $p.Pattern, $_.Exception.Message)
        continue
    }
    if ($hits.Count -gt 0) {
        $matched += [pscustomobject]@{
            Pattern     = $p.Pattern
            PatternPath = $p.PatternPath
            Trigger     = $p.Trigger
            Matches     = @($hits)
        }
    }
}

# 6. Report.
$matched
Write-Host ("{0} of {1} pattern triggers match this diff ({2} added lines scanned; {3} patterns have trigger none, {4} have no trigger line)." -f `
    @($matched).Count, @($patterns).Count, $scan.Count, $noneTrigger, $noTrigger)
if (@($matched).Count -gt 0) {
    Write-Host 'Read each matched pattern file and apply its check before committing.'
}
exit 0
