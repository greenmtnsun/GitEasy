[CmdletBinding()]
param(
    [string]$TestsRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Tests')
)

$ErrorActionPreference = 'Stop'

# Phase 1: Migrate legacy `Should X` -> `Should -X` syntax across all .Tests.ps1 files.
# Order matters: longest / most-specific patterns first to avoid partial-replace collisions.
$replacements = [ordered]@{
    'Should Not BeNullOrEmpty'   = 'Should -Not -BeNullOrEmpty'
    'Should Not BeOfType '       = 'Should -Not -BeOfType '
    'Should Not BeGreaterThan '  = 'Should -Not -BeGreaterThan '
    'Should Not BeLessThan '     = 'Should -Not -BeLessThan '
    'Should Not BeExactly '      = 'Should -Not -BeExactly '
    'Should Not BeLike '         = 'Should -Not -BeLike '
    'Should Not HaveCount '      = 'Should -Not -HaveCount '
    'Should Not Match '          = 'Should -Not -Match '
    'Should Not Contain '        = 'Should -Not -Contain '
    'Should Not FileContentMatch ' = 'Should -Not -FileContentMatch '
    'Should Not Exist'           = 'Should -Not -Exist'
    'Should Not Throw'           = 'Should -Not -Throw'
    'Should Not Be '             = 'Should -Not -Be '
    'Should BeOfType '           = 'Should -BeOfType '
    'Should BeGreaterThan '      = 'Should -BeGreaterThan '
    'Should BeLessThan '         = 'Should -BeLessThan '
    'Should BeExactly '          = 'Should -BeExactly '
    'Should BeLike '             = 'Should -BeLike '
    'Should BeNullOrEmpty'       = 'Should -BeNullOrEmpty'
    'Should HaveCount '          = 'Should -HaveCount '
    'Should FileContentMatch '   = 'Should -FileContentMatch '
    'Should Match '              = 'Should -Match '
    'Should Contain '            = 'Should -Contain '
    'Should Exist'               = 'Should -Exist'
    'Should Throw'               = 'Should -Throw'
    'Should Be '                 = 'Should -Be '
}

$files = @(
    Get-ChildItem -LiteralPath $TestsRoot -Filter '*.Tests.ps1' -File
    Get-ChildItem -LiteralPath (Join-Path $TestsRoot 'Unit') -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue
)

Write-Host "[Phase 1] Migrating Should syntax across $($files.Count) files..."
foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $orig = $text
    foreach ($pair in $replacements.GetEnumerator()) {
        # Use simple string replacement, not regex - patterns include spaces and no special chars.
        $text = $text.Replace($pair.Key, $pair.Value)
    }
    if ($text -ne $orig) {
        Set-Content -LiteralPath $file.FullName -Value $text -NoNewline -Encoding UTF8
        Write-Host "  syntax: $($file.Name)"
    }
}

# Phase 2: Wrap pre-Describe script-top region in BeforeAll { ... } so vars and helper
# functions are visible inside Pester 5 BeforeAll/BeforeEach/It scopes.
# Strategy: read each file's tokenized AST, find the first 'Describe' command at script-block
# top level, and wrap everything before it (excluding comments-only headers) in BeforeAll.
Write-Host "[Phase 2] Fixing script-top scoping..."
foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    if ($text -match '(?m)^\s*BeforeAll\s*\{') {
        # Already has a top-level BeforeAll wrapper - skip
        # (but verify it's BEFORE the first Describe)
    }

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) {
        Write-Warning "  parse errors in $($file.Name); skipping scoping fix"
        continue
    }

    # Find the first top-level CommandAst whose first element is 'Describe'
    $topStatements = $ast.EndBlock.Statements
    $firstDescribeOffset = $null
    foreach ($stmt in $topStatements) {
        $cmd = $stmt.PipelineElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandAst] } | Select-Object -First 1
        if ($cmd) {
            $firstElement = $cmd.CommandElements | Select-Object -First 1
            if ($firstElement -and $firstElement.Value -eq 'Describe') {
                $firstDescribeOffset = $stmt.Extent.StartOffset
                break
            }
        }
    }

    if ($null -eq $firstDescribeOffset) {
        Write-Warning "  no Describe block found in $($file.Name); skipping"
        continue
    }

    $head = $text.Substring(0, $firstDescribeOffset)
    $body = $text.Substring($firstDescribeOffset)

    # If $head has only comments/whitespace, nothing to wrap.
    $headStripped = ($head -replace '(?m)^\s*#.*$', '').Trim()
    if ([string]::IsNullOrWhiteSpace($headStripped)) {
        continue
    }

    # If $head already starts with BeforeAll { ... }, leave it alone.
    if ($head -match '(?ms)^\s*BeforeAll\s*\{.*\}\s*$') {
        continue
    }

    # Extract any pure leading comment block to keep it ABOVE BeforeAll for readability.
    $leadingComments = ''
    $rest = $head
    if ($head -match '\A((?:^\s*(?:#.*)?\r?\n)+)') {
        $leadingComments = $matches[1]
        $rest = $head.Substring($leadingComments.Length)
    }

    # Wrap $rest in BeforeAll WITHOUT re-indenting interior lines - here-strings forbid
    # whitespace before the terminating "@ / '@ marker, so leave content as-is.
    $wrapped = $leadingComments + 'BeforeAll {' + [Environment]::NewLine + $rest.TrimEnd() + [Environment]::NewLine + '}' + [Environment]::NewLine + [Environment]::NewLine

    $newText = $wrapped + $body
    if ($newText -ne $text) {
        Set-Content -LiteralPath $file.FullName -Value $newText -NoNewline -Encoding UTF8
        Write-Host "  scope:  $($file.Name)"
    }
}

Write-Host 'Done.'
