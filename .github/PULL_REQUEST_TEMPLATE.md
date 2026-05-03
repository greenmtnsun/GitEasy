## Summary

What does this PR change, in one or two sentences?

## Why

What problem does it solve? Reference an issue if there is one.

## Checklist

- [ ] Tests pass on Windows PowerShell 5.1 (`.\tools\Run-GitEasyPester.ps1`)
- [ ] Tests pass on PowerShell 7+
- [ ] Jargon audit clean: `.\tools\Audit-PublicJargon.ps1` reports 0 HARD hits
- [ ] Wiki refresh dry-run is clean: `.\Update-GitEasyCommandWiki.ps1 -DryRun`
- [ ] CBH on every changed function (`.SYNOPSIS`, `.DESCRIPTION`, per-`.PARAMETER`, at least one `.EXAMPLE`)
- [ ] Diagnostic log session for any new public command
- [ ] CHANGELOG.md updated
