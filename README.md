# GitEasy

A PowerShell module that lets a Git-clueless person save and publish their work without learning Git jargon.

## What it gives you

A small set of plain-English commands. The complicated stuff stays inside the engine; what you see and type stays simple.

```powershell
Find-CodeChange         # What has changed?
Save-Work 'fix readme'  # Save and publish in one step.
Show-History            # Recent saved points.
Show-Remote             # Where this folder is published.
```

When something goes wrong, you get a plain-English message and a path to a self-contained log file with the technical detail. No raw Git output is ever shown to the user.

## Install

This module is local-install for now (no PowerShell Gallery release yet). Clone or copy it somewhere on your `$env:PSModulePath`, or import directly:

```powershell
Import-Module 'C:\Sysadmin\Scripts\GitEasy\GitEasy.psd1' -Force
```

## Quickstart

```powershell
# In any folder that is already a Git repo:
Find-CodeChange
Save-Work 'first save'
Show-History -Count 5
```

If the repo has not been published anywhere yet, Save-Work will tell you so and save locally. When you connect a published location later, the next Save-Work will publish everything you have saved up to that point.

## The full command surface

| Command | What it does |
|---|---|
| `Find-CodeChange` | Show what has changed in your project folder. |
| `Save-Work` | Save changes and publish them (or save locally with `-NoPush`). |
| `Show-History` | Show recent saved points. |
| `Show-Remote` | Show where the project folder is published. |
| `Show-Diagnostic` | Open or list the diagnostic log files. |
| `New-WorkBranch` | Start a new working area for an isolated task. |
| `Switch-Work` | Switch to another existing working area. |
| `Restore-File` | Restore a single file to its last saved state. |
| `Undo-Changes` | Throw away unsaved changes (requires `-Force` or `-Confirm`). |
| `Clear-Junk` | List or remove obvious temporary files. |
| `Test-Login` | Verify connectivity to the published location. |
| `Set-Token` | Configure HTTPS-based login. |
| `Set-Ssh` | Configure SSH-based login. |
| `Set-Vault` | Choose where saved logins are stored. |
| `Get-VaultStatus` | Report the configured credential helper. |
| `Reset-Login` | Forget the saved login so it can be set up again. |

Each command has full comment-based help — `Get-Help <Command> -Full` for the friendly version.

## Diagnostic logs

Every public command writes a small log file under `%LOCALAPPDATA%\GitEasy\Logs`. Successful runs log silently. Failures throw a plain-English message and tell you the log path so a Git-aware person can read what happened.

```powershell
Show-Diagnostic           # Open the most recent log.
Show-Diagnostic -List     # List recent logs.
Show-Diagnostic -All      # Open the logs folder.
```

Logs older than 30 days are pruned automatically.

## Documentation

The full documentation lives in the [GitHub Wiki](https://github.com/greenmtnsun/GitEasy/wiki). Every public command has its own page with synopsis, examples, safety notes, and a related-commands cross-reference. Every private helper has a similar page for maintainers.

## Compatibility

- **Windows PowerShell 5.1+**
- **PowerShell 7+** (Windows; cross-platform may work but is not the design target)
- **Git** must be installed and on `PATH`.

## Status

GitEasy is at **1.0.0** — feature-complete public surface, comprehensive Pester coverage on both PowerShell hosts, and full plain-English contract.

See [CHANGELOG.md](CHANGELOG.md) for the history.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The short version: every user-facing string stays plain English, every change ships with Pester tests, and the diagnostic-log session pattern is the standard for any new public command.

## License

[Mozilla Public License 2.0](LICENSE). File-level copyleft: anyone can use, modify, and embed this code in proprietary or open projects, but modifications to GitEasy's own files must be released under MPL-2.0.

## Author

Keith Ramsey ([@greenmtnsun](https://github.com/greenmtnsun)).
