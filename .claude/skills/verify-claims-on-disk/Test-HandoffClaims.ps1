<#
.SYNOPSIS
    Verifies the machine-checkable Claims block of a handoff doc against actual disk state.

.DESCRIPTION
    Handoff docs may carry a '## Claims' section listing what the writing session says
    landed on disk. This checker parses that section and verifies each claim, so a
    consuming session can gate on real state instead of trusting prose.

    Claims block format (one claim per line, inside a '## Claims' section):

        ## Claims
        - file: C:\Path\To\File.ps1  contains: literal text expected in the file
        - file: C:\Path\To\File.ps1  pattern: regex\s+expected
        - file: C:\Path\To\File.ps1  absent: literal text that must NOT be present
        - file: C:\Path\To\NewFile.ps1

    A bare 'file:' line is an existence-only claim. Relative paths resolve against
    -Root (defaults to the handoff doc's own directory).

    Gate semantics match the workspace hook conventions: fail-open when the doc has
    no Claims block (exit 0 with a NO-CLAIMS notice — legacy handoffs still work),
    hard-fail (exit 1) when any stated claim does not match disk.

    Steps:
    1. Validate the handoff doc exists; emit BAD-INPUT and exit 1 if not.
    2. Extract the '## Claims' section (lines until the next '#' heading).
    3. Parse each '- file:' line into path, check type (Exists/Contains/Pattern/Absent), and expected value.
    4. Resolve relative paths against -Root.
    5. Existence check every claimed file; content-check Contains/Pattern/Absent claims via Select-String.
    6. Emit one structured result object per claim (File, Check, Expected, Result, Detail).
    7. Exit 0 if every claim passed (or no Claims block); exit 1 if any claim failed.

.PARAMETER HandoffPath
    Path to the handoff .md file to verify.

.PARAMETER Root
    Base directory for resolving relative file paths in claims.
    Defaults to the handoff doc's own directory.

.EXAMPLE
    .\Test-HandoffClaims.ps1 -HandoffPath C:\Users\keith\.claude\cross-project-artifacts\GitEasy-mcp-fixes-2026-07-17.md

    Run from anywhere (all paths are explicit). Verifies every claim in the handoff.
    Success check: each output row shows Result PASS and the script exits 0.

.EXAMPLE
    .\Test-HandoffClaims.ps1 -HandoffPath .\PesterForge-phase3-2026-07-17.md | Where-Object Result -ne 'PASS'

    Show only the claims that failed verification. An empty result means the
    handoff is safe to build on.

.EXAMPLE
    .\Test-HandoffClaims.ps1 -HandoffPath $doc; if ($LASTEXITCODE -ne 0) { Write-Warning 'Do NOT build on this handoff.' }

    Gate usage: a consuming session runs the checker before acting on the handoff
    and stops when the exit code signals drift between claims and disk.

.NOTES
    Companion to the verify-claims-on-disk skill; authored 2026-07-17.
    Two incidents motivated this gate: 2026-05-06 (dispatch claimed 3 fixes, 0 applied)
    and 2026-05-08 (overnight loop claimed 6 fixes, 0 shipped).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$HandoffPath,

    [Parameter(Mandatory = $false)]
    [string]$Root
)

$results = @()

if (-not (Test-Path -LiteralPath $HandoffPath)) {
    [pscustomobject]@{
        File     = $HandoffPath
        Check    = 'HandoffDoc'
        Expected = 'handoff doc exists'
        Result   = 'BAD-INPUT'
        Detail   = 'Handoff doc not found on disk.'
    }
    exit 1
}

$handoffFile = Get-Item -LiteralPath $HandoffPath
if (-not $Root) { $Root = $handoffFile.DirectoryName }

# Extract the '## Claims' section: lines after the heading, up to the next heading.
$lines = @(Get-Content -LiteralPath $HandoffPath -Encoding UTF8)
$claimLines = @()
$inClaims = $false
foreach ($line in $lines) {
    if ($line -match '^\s*##\s+Claims\s*$') { $inClaims = $true; continue }
    if ($inClaims -and $line -match '^\s*#') { break }
    if ($inClaims) { $claimLines += $line }
}

if (-not $inClaims) {
    [pscustomobject]@{
        File     = $HandoffPath
        Check    = 'ClaimsBlock'
        Expected = "'## Claims' section"
        Result   = 'NO-CLAIMS'
        Detail   = 'No Claims block found; nothing to verify (fail-open). Consider adding one per the handoff skill.'
    }
    exit 0
}

foreach ($line in $claimLines) {
    if ($line -notmatch '^\s*-\s*file:\s*(.+)$') { continue }
    $rest = $Matches[1].Trim()

    # Split path from an optional check keyword; first keyword occurrence wins.
    $check = 'Exists'; $expected = $null; $path = $rest
    if ($rest -match '^(.*?)\s+(contains|pattern|absent):\s*(.+)$') {
        $path = $Matches[1].Trim()
        $check = (Get-Culture).TextInfo.ToTitleCase($Matches[2])
        $expected = $Matches[3].Trim()
    }

    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path -Path $Root -ChildPath $path
    }

    if (-not (Test-Path -LiteralPath $path)) {
        $results += [pscustomobject]@{
            File     = $path
            Check    = $check
            Expected = $expected
            Result   = 'MISSING'
            Detail   = 'Claimed file does not exist on disk.'
        }
        continue
    }

    switch ($check) {
        'Exists' {
            $results += [pscustomobject]@{
                File = $path; Check = $check; Expected = 'file exists'
                Result = 'PASS'; Detail = 'File present.'
            }
        }
        'Contains' {
            $hit = Select-String -LiteralPath $path -Pattern $expected -SimpleMatch -Quiet
            $results += [pscustomobject]@{
                File = $path; Check = $check; Expected = $expected
                Result = $(if ($hit) { 'PASS' } else { 'FAIL' })
                Detail = $(if ($hit) { 'Literal text found.' } else { 'Claimed text NOT found in file.' })
            }
        }
        'Pattern' {
            $hit = Select-String -LiteralPath $path -Pattern $expected -Quiet
            $results += [pscustomobject]@{
                File = $path; Check = $check; Expected = $expected
                Result = $(if ($hit) { 'PASS' } else { 'FAIL' })
                Detail = $(if ($hit) { 'Regex matched.' } else { 'Claimed pattern did NOT match file.' })
            }
        }
        'Absent' {
            $hit = Select-String -LiteralPath $path -Pattern $expected -SimpleMatch -Quiet
            $results += [pscustomobject]@{
                File = $path; Check = $check; Expected = $expected
                Result = $(if ($hit) { 'FAIL' } else { 'PASS' })
                Detail = $(if ($hit) { 'Text claimed removed is STILL present.' } else { 'Text absent as claimed.' })
            }
        }
    }
}

if (@($results).Count -eq 0) {
    $results += [pscustomobject]@{
        File     = $HandoffPath
        Check    = 'ClaimsBlock'
        Expected = 'at least one parseable claim line'
        Result   = 'NO-CLAIMS'
        Detail   = 'Claims section present but no parseable ''- file:'' lines (fail-open).'
    }
    $results
    exit 0
}

$results
$failed = @($results | Where-Object { $_.Result -in @('FAIL', 'MISSING') })
if ($failed.Count -gt 0) { exit 1 } else { exit 0 }
