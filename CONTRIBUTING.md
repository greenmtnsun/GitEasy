# Contributing to GitEasy

## The core rule

**The user surface stays plain English.** GitEasy exists for people who do not know Git terminology and should not have to. Engine-side complexity is welcome; user-side jargon is a bug as serious as any functional defect.

## Before opening a PR

1. **Run the full Pester suite** on Windows PowerShell 5.1 and PowerShell 7+:
   ```powershell
   .\tools\Run-GitEasyPester.ps1
   ```
   All tests must pass on both.

2. **Run the jargon audit**:
   ```powershell
   .\tools\Audit-PublicJargon.ps1
   ```
   `HARD jargon hits` must be zero. SOFT hits should be reviewed in context (sticky words like "branch", "commit", "push" are sometimes unavoidable).

3. **Run the wiki refresh in dry-run mode**:
   ```powershell
   .\Update-GitEasyCommandWiki.ps1 -DryRun
   ```
   Address any drift, CBH gaps, or stale-claim hits the report flags.

## Style rules

- **Atomic scripts** — every standalone script opens with a STATE CHECK that validates inputs, sets `$ErrorActionPreference = 'Stop'`, and uses explicit absolute paths. No `$PSScriptRoot` in user-facing scripts.
- **No here-strings** for generated file content — use arrays of lines.
- **GE-prefix for private helpers** — `Get-GERepoRoot.ps1`, `Test-GERepositoryBusy.ps1`, etc.
- **Commit messages without UTF-8 BOM** — write temp files via `[System.IO.File]::WriteAllText($path, $msg, [System.Text.UTF8Encoding]::new($false))`.
- **Use `Invoke-GEGit`** for every Git call from a public command. Do not run `git ...` directly in a public function.
- **Plain-English errors** — public commands catch technical exceptions, log the detail to a diagnostic file, and throw a friendly message that ends with `Details: <log-path>`.

## Testing discipline

- **TDD for behavior changes.** Write the failing Pester test first; commit only after it passes.
- **Pester 3 syntax.** GitEasy targets the Pester version that ships with Windows PowerShell 5.1. Use `Should Be`, `Should Match`, `Should Not BeNullOrEmpty`. Do not use Pester 5 operator syntax (`Should -Be`, `BeforeAll`, `-Tag`).
- **`Should Throw` is broken on PowerShell 7 with Pester 3.** Use `try/catch` + `Should Not BeNullOrEmpty` instead. This pattern works on both 5.1 and 7.
- **Integration tests are the dominant style.** Spin up a real temp Git repo and a real bare remote in `BeforeEach`; tear them down in `AfterEach`.

## Diagnostic logs are mandatory for new public commands

Every new public command must follow the per-invocation log pattern:

```powershell
$session = Start-GELogSession -Command 'New-Command' -Repository $repoRoot -LogPath $LogPath

try {
    # ... work, threading $session.Path into Invoke-GEGit calls ...
    Complete-GELogSession -Path $session.Path -Outcome 'SUCCESS'
}
catch {
    Complete-GELogSession -Path $session.Path -Outcome 'FAILURE' -UserMessage $msg -ErrorMessage $_.Exception.Message
    throw "$msg Details: $($session.Path)"
}
```

## Comment-based help is mandatory

Every public command, every private helper, and every script ships with a CBH block: `.SYNOPSIS`, `.DESCRIPTION`, per-`.PARAMETER`, at least one `.EXAMPLE`, `.NOTES` for safety remarks, and `.LINK` for related commands. The wiki refresh script generates pages from this CBH; missing CBH means missing wiki content.

## Wiki

The wiki is a separate Git repository (`<repo>.wiki.git`). After source changes, run:

```powershell
.\Update-GitEasyCommandWiki.ps1
.\Update-GitEasyPrivateWiki.ps1
```

Both scripts audit the resulting pages and fail if any required heading is missing.

## License

GitEasy is licensed under the [Mozilla Public License 2.0](LICENSE). By contributing, you agree your contributions are licensed under the same terms.
