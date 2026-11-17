# PowerShell module hygiene patterns — captured from a Gemini conversation

> **Origin:** Gemini share `https://gemini.google.com/share/54386437a2bc`, pasted by Keith 2026-05-07.
> **Framing note:** Gemini wrote this as the "Agnostic Gold Standard Manifesto" / "Master Directive." That language overclaims. The patterns below are **standard PowerShell module hygiene** as practiced by mature projects — dbatools, PSFramework, PoshCode, ModuleBuilder. They are not novel discoveries or a proprietary methodology; they're established conventions worth adopting. When citing this document in skills or DRs, refer to the patterns directly (e.g. "the dynamic-loader pattern," "messages-vault pattern"), not to "the Agnostic Gold Standard." Keep the framing humble — the substance is solid; the marketing was Gemini's.
> **Naming note:** Gemini called this "FluentDba" because that's one of Keith's email handles, not because there is a project of that name. When encoding rules into skills, **strip the FluentDba / Fda branding** and use `<Prefix>` / `<Project>` tokens. Keith's neutral-framing rule applies (see `feedback_neutral_developer_framing.md`).
> **Filter applied:** "vCEO" / CEO / virtual-roles framing is dropped per Keith's earlier instruction.

---

## 1. Air Gap Philosophy

- **Environment Blindness** — code does not know whether it's running in a work environment, on a CI runner, or on a personal machine.
- **Zero Metadata Leakage** — no machine names, domain prefixes (e.g. `DOMAIN\`), IPs in source.
- **Standalone Integrity** — each module is independent. Modules share *patterns* (DNA), not *code* (cross-deps).

## 2. Structural Standards (dbatools-derived)

```
/public                  Exported cmdlets, one function per file
/internal/functions      Private engine logic
/internal/messages       messages.psd1 string vault
/internal/configurations Default settings (Config.ps1)
/data                    Static T-SQL or JSON lookups
/tests                   Pester 5+
/docs                    Markdown / JSON wiki source
```

## 3. Agnostic Core Components

### A. Dynamic Loader (`<Project>.psm1`)

Uses `$PSScriptRoot` + `$MyInvocation` to discover and dot-source all functions. No hardcoded function list in the manifest.

### B. Configuration Engine

`Get-<Prefix>Config -SettingName 'X'`. Defaults live in the module; overrides live in the user's `$PROFILE`.

### C. Messaging Vault (`messages.psd1`)

Logic separated from text. **No inline strings in functions.** Pattern: `Write-<Prefix>Message -Id 'Connecting' -Args $Server`. The vault enables 100% metadata scrubbing — if a string isn't in the vault, it never reaches the user.

### D. Input Standardizer

`Get-<Prefix>Input` converts strings, CSV rows, and custom objects into a standardized object before processing. Pipeline-greedy without environment knowledge.

## 4. Hardening Rules

- **No here-strings.** `@"..."@` and `@'...'@` are banned. Multi-line strings use the `-join` line-array pattern:

  ```powershell
  $Sql = @(
      "SELECT name"
      "FROM sys.databases"
  ) -join "`r`n"
  ```

- **Native-only by default.** Prefer .NET Reflection or CIM over SMO / RMO when possible. Per `feedback_python_encapsulation.md`, **Python is permitted behind a PowerShell-shaped surface** even in suite modules — the rule the directive captures is "no naked Python in business code," not zero-Python. PowerShell-shaped helpers may shell out to Python internally with a JSON handshake; users see PowerShell objects, never `& python` calls. PhotoOrganizer's Python use (face_recognition + sklearn DBSCAN) is the canonical example.
- **Conditional Dependency Gatekeeper.** When a native DLL is required (e.g. RMO for replication scenarios), guard the import so a missing DLL does not hard-crash module load.
- **ShouldProcess.** Every state-changing command supports `-WhatIf` and `-Confirm`.

## 5. Documentation & Metadata

- **Comment-Based Help** on every public function: `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE` minimum.
- **JSON Wiki Source.** Function metadata exports to `Wiki_Data.json` for programmatic wiki generation. (Aligns with the Module Suite's existing schema-as-contract framing.)
- **Independent Logging.** Each module writes its own transcript to `Documents\<Project>\Logs\<ModuleName>\`. No centralized infra.

## 6. Pre-Release Audit Checklist

Before any module is considered v1.0:

1. Does it load without errors via the dynamic `.psm1`?
2. Are there any hardcoded user-facing strings outside `messages.psd1`?
3. Are there any here-strings in the codebase?
4. Does `-WhatIf` succeed without making changes?
5. Is it 100% portable to a machine that has never seen sibling modules?
