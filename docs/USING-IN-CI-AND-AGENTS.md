# Using GitEasy from CI or an AI agent

This page is the contract for **consumers** of GitEasy — your CI job
(GitHub Actions, Azure Pipelines, GitLab CI, anything with `pwsh`), or
an AI coding agent (Claude session, Copilot, etc.) that's been handed a
folder and told to use GitEasy as a tool.

You don't need to run GitEasy's own test suite or jargon audit in your
pipeline. Those are the author's quality bars, not yours — they tell
you about my code, not yours. If GitEasy ever fails its own tests,
that's a bug to file on me, not a step in your build.

---

## 1. What you need

| Need | Why | How to check |
|---|---|---|
| **PowerShell 5.1 or 7+** | GitEasy is a PowerShell module. | `$PSVersionTable` |
| **git on `PATH`** | Every GitEasy command runs `git` under the hood. | `git --version` |
| **Windows** (primary) | Built and tested on Windows. PS 7 on Linux / macOS works for read-only commands; credential-aware commands are Windows-shaped. | `$IsWindows` |
| **Network access** to your remote | `Save-Work` pushes to GitHub / GitLab / Bitbucket / Azure DevOps / Gitea. | `Test-Login` |

That's the full prerequisite list. No test framework. No build tools.
GitEasy itself is what you're using; it isn't something you compile.

---

## 2. Install GitEasy in your job

### A. From a folder you cloned (works today)

```powershell
git clone https://github.com/greenmtnsun/GitEasy.git $env:RUNNER_TEMP\GitEasy
Import-Module $env:RUNNER_TEMP\GitEasy\GitEasy.psd1 -Force
```

`$env:RUNNER_TEMP` is the GitHub Actions per-job temp folder. On other
CI systems use whatever per-job temp path that runner provides
(`$env:AGENT_TEMPDIRECTORY` on Azure Pipelines, `$CI_PROJECT_DIR/tmp`
on GitLab, etc.).

### B. From PowerShell Gallery (once published)

```powershell
Install-Module GitEasy -Scope CurrentUser -Force
Import-Module GitEasy
```

GitEasy is not yet on PowerShell Gallery as of v1.5.3. When it ships,
this becomes the one-line install and replaces option A.

---

## 3. Smoke test (run once after install)

Three lines that prove GitEasy is loaded and healthy:

```powershell
Import-Module GitEasy
(Get-Command -Module GitEasy).Count       # should print 21
Get-Help Save-Work -Examples              # should print examples
```

If all three return what's expected, GitEasy is ready. No further
"is GitEasy itself OK?" checks belong in your CI — GitEasy's own tests
verify GitEasy, and they run on every GitEasy release, not in your
pipeline.

---

## 4. Use it in your pipeline

GitEasy commands run inside any folder that's already a git repository
(has a hidden `.git` folder). Daily-save example:

```powershell
Set-Location $env:GITHUB_WORKSPACE   # or whichever working folder
Save-Work "automated config update from CI"
```

`Save-Work` returns a small object you can branch on:

```powershell
$r = Save-Work "automated update"
if (-not $r.Passed) {
    Write-Error "Save failed: $($r.Message). See $($r.LogPath) for the trail."
    exit 1
}
```

Every state-changing command returns at least `Passed`, `Message`, and
`LogPath`. The full return-object shape per command lives in
[`docs/FOR-GIT-EXPERTS.md`](FOR-GIT-EXPERTS.md).

---

## 5. CI recipe (GitHub Actions, Windows)

This is the full minimal job that installs GitEasy and runs one save:

```yaml
jobs:
  giteasy-save:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install GitEasy
        shell: powershell
        run: |
          git clone https://github.com/greenmtnsun/GitEasy.git `
            $env:RUNNER_TEMP\GitEasy
          Import-Module $env:RUNNER_TEMP\GitEasy\GitEasy.psd1 -Force
          (Get-Command -Module GitEasy).Count   # smoke check

      - name: Save and publish
        shell: powershell
        run: |
          $r = Save-Work "automated CI update"
          if (-not $r.Passed) { throw $r.Message }
```

**The same PowerShell stays identical on every CI platform** — only the
YAML wrapper changes:

- **Azure Pipelines:** `task: PowerShell@2` with `pwsh: false` for PS 5.1
  or `pwsh: true` for PS 7.
- **GitLab CI:** put the PowerShell into a `.ps1` file and run
  `pwsh -NoProfile -File install-and-save.ps1` from the runner.
- **Generic pwsh runner:** put the install + smoke-check + save into a
  `.ps1` and call it. No shell-escape gymnastics needed.

The single-file `.ps1` form is preferred over piping multi-line strings
through `pwsh -c "..."` — it's easier to maintain, easier to debug, and
doesn't break when a CI system's YAML parser eats a backslash.

---

## 6. Notes for AI / agent consumers

If you are an AI session driving this module (Claude, Copilot, etc.):

**Read-only commands** (safe to call any time, no `-WhatIf` needed):
`Find-CodeChange`, `Show-History`, `Show-Remote`, `Show-Releases`,
`Show-Change`, `Show-Diagnostic`, `Search-History`, `Get-VaultStatus`,
`Test-Login`.

**State-changing commands** (all support `-WhatIf` for dry runs):
`Save-Work`, `New-Release`, `New-WorkBranch`, `Switch-Work`,
`Restore-File`, `Undo-Changes`, `Clear-Junk`, `Set-Token`, `Set-Ssh`,
`Set-Vault`, `Reset-Login`, `Get-Updates`.

**Things that are true and worth knowing:**

- Every command returns a structured object. Don't parse text output —
  read the properties.
- Credentials are stripped from log files and return objects before
  they hit disk. You can show users a `LogPath` without worrying.
- Every state-changing command writes one log file at
  `%LOCALAPPDATA%\GitEasy\Logs`. `Show-Diagnostic` opens the most
  recent.
- `Save-Work` does four `git` things in one call (stage, commit, pull
  --rebase, push). It's a recipe, not a single git command.

**Three things not to do:**

- **Don't shell out to `git` directly** — use GitEasy commands. Raw
  `git` calls skip the log session and the credential scrub.
- **Don't pass remote URLs with tokens embedded** — `Set-Token` and
  `Set-Ssh` reject `https://token@host/...` shapes on purpose.
- **Don't try to merge branches with GitEasy** — it's append-only by
  design. For `git rebase -i`, `git merge`, `git cherry-pick`, drop to
  raw git in the same folder; nothing GitEasy did blocks you.

---

## 7. Cross-platform caveats

Windows is the supported target. PS 7 on Linux / macOS works for the
read-only commands listed above. For state-changing commands:

- `Save-Work` works if the remote is reachable and your credential
  helper is already configured for the platform (`osxkeychain` on macOS,
  `libsecret` / `cache` on Linux).
- `Set-Token`, `Set-Ssh`, `Set-Vault`, `Reset-Login` assume Windows
  credential helpers (Windows Credential Manager / Git Credential
  Manager). They may report success on non-Windows hosts without doing
  the expected thing — treat credential commands as Windows-only.
- Diagnostic log path defaults to `%LOCALAPPDATA%`, which is empty on
  non-Windows. Pass `-LogPath` explicitly if you need durable logs on
  Linux / macOS.

If you only need to *read* git state in CI (most agent use cases),
PS 7 on Linux / macOS is fine.

---

## 8. Where to go next

- [`HOW-TO-USE-GITEASY.md`](HOW-TO-USE-GITEASY.md) — the beginner walk-
  through with diagrams. Skim it once even if you're an agent.
- [`FOR-GIT-EXPERTS.md`](FOR-GIT-EXPERTS.md) — exact return-object
  shapes per command, log-file layout, override knobs, raw-git
  fallback patterns.
- [`GITEASY-VS-RAW-GIT.md`](GITEASY-VS-RAW-GIT.md) — every GitEasy
  command shown next to the raw `git` calls it actually runs.
