# GitEasy vs Raw Git: Side-by-Side

This guide shows the same job done two ways. **GitEasy** on one side.
**Plain Git (the long tech way)** on the other. The idea is simple:
GitEasy turns 2 to 5 careful Git steps into one easy command.

> **What this side-by-side proves.** *No hidden magic.* Every GitEasy
> command on the left is the exact set of `git` calls on the right. If
> you ever want to drop down to raw Git for one operation, the same
> folder, the same `.git/`, and the same login work fine. GitEasy is a
> wrapper, not a fork of Git — you are not losing functionality by
> using it.
>
> Every "Plain Git" box below shows the real `git` commands GitEasy runs
> for you under the hood. Nothing is made up. These are the commands you
> would have to type yourself if GitEasy did not exist.

---

## At a glance

| Job | GitEasy (one command) | Plain Git (steps) |
|---|---|---|
| Save and put it online (push) | `Save-Work 'msg'` | 4 |
| Save only on your computer | `Save-Work 'msg' -NoPush` | 2 |
| See what you changed | `Find-CodeChange` | 3 |
| Show recent saves | `Show-History -Count 5` | 1 (with hard-to-remember flags) |
| Show your online home | `Show-Remote` | 2 |
| Check your login | `Test-Login` | 2 |
| Set up a normal-web (HTTPS) login | `Set-Token -RemoteUrl '…'` | 1 (and easy to get wrong) |
| Switch to key-based (SSH) login | `Set-Ssh` | 1 to 2 + URL editing |
| Forget a bad saved login | `Reset-Login` | 2 to 3 |
| Bring back one file | `Restore-File path` | 2 |
| Throw away all changes | `Undo-Changes -Force` | 2 |
| Start a new working area | `New-WorkBranch name` | 2 |
| Switch working area | `Switch-Work name` | 1 (after a status check) |
| Clean junk files | `Clear-Junk -Force` | 2 |

---

## 1. Save your work and put it online

This is the big one. With plain Git you must mark files, save a point,
fetch your teammates' work, replay yours on top, and then send it. Five
ideas. Four commands. With GitEasy it is one word.

**GitEasy**
```powershell
Save-Work 'fix readme'
```

**Plain Git (the long tech way)**
```bash
git add --all                     # mark every changed file to be saved (stage)
git commit -m "fix readme"        # record a saved point (commit)
git pull --rebase                 # pull teammates' work and replay yours on top
git push                          # send your saves to the online home
```

If your **working area (branch)** has never been online before:

**GitEasy**
```powershell
Save-Work 'first online save' -SetUpstream
```

**Plain Git**
```bash
git add --all
git commit -m "first online save"
git push -u origin <branch-name>   # you must know the branch name to type here
```

> GitEasy also refuses to run while a half-done merge or replay
> (merge/rebase/cherry-pick/revert/bisect) is in progress, checks your
> note, and writes a log file. Plain Git lets you stack a bad save on
> top of a half-finished one.

## 2. Save only on your computer (no online publish)

**GitEasy**
```powershell
Save-Work 'checkpoint before refactor' -NoPush
```

**Plain Git**
```bash
git add --all
git commit -m "checkpoint before refactor"
```

## 3. See what you changed

GitEasy gives you one tidy view. Plain Git makes you remember three
different views (changed-but-unsaved, marked-to-save, and brand-new
files) and add them up in your head.

**GitEasy**
```powershell
Find-CodeChange
```

**Plain Git**
```bash
git status --short --untracked-files=normal      # short list of all changes
git diff --stat                                  # which lines changed in files
git diff --cached --stat                         # which lines are already marked
```

## 4. Show your recent saves

The plain Git form is one line, but it is one line nobody remembers.

**GitEasy**
```powershell
Show-History -Count 5
```

**Plain Git**
```bash
git log --max-count=5 --date=short \
  --pretty=format:%h%x09%ad%x09%an%x09%s
```

## 5. Show your online home

**GitEasy**
```powershell
Show-Remote
```

**Plain Git**
```bash
git remote -v                            # show the online address
git symbolic-ref --short HEAD            # show which working area you are on
```

## 6. Check that your login works

**GitEasy**
```powershell
Test-Login
```

**Plain Git**
```bash
git remote                               # is there an online home set?
git ls-remote --heads origin             # can I reach it with my login?
```

> GitEasy also gives back a tidy `Passed = True/False` result you can use
> in another script. Plain Git makes you read the output yourself.

## 7. Set up a normal-web (HTTPS) online home

**GitEasy**
```powershell
Set-Token -RemoteUrl 'https://github.com/you/repo.git'
```

**Plain Git (first time)**
```bash
git remote add origin https://github.com/you/repo.git
```

**Plain Git (changing an existing one)**
```bash
git remote set-url origin https://github.com/you/repo.git
```

> GitEasy picks "add" vs "change" for you. It also **refuses addresses
> with a password inside them** (like `https://token@host/…`) so secrets
> never end up saved in a settings file. Plain Git lets you paste a
> password into the address and forget it is there.

## 8. Switch to key-based (SSH) login

**GitEasy**
```powershell
Set-Ssh
```

**Plain Git**
```bash
git remote -v                                        # find the current address
git remote set-url origin git@github.com:you/repo.git
```

> GitEasy rewrites the address for you, including the host swap and the
> trailing `.git`.

## 9. Forget a bad saved login

This one trips up everyone. The plain Git fix is not friendly.

**GitEasy**
```powershell
Reset-Login
```

**Plain Git (one of several ways, depending on which login keeper you use)**
```bash
printf "protocol=https\nhost=github.com\n\n" | git credential reject
printf "protocol=https\nhost=github.com\n\n" | git credential-manager erase
git config --global --get credential.helper        # to know which to call
```

> On Windows, GitEasy also clears matching entries in the Windows
> password vault (`cmdkey`). Plain Git needs you to know to do that
> separately.

## 10. Bring back one file

**GitEasy**
```powershell
Restore-File README.md
```

**Plain Git**
```bash
git ls-files --error-unmatch -- README.md     # check the file is known to Git
git checkout -- README.md                     # put it back to last saved
```

## 11. Throw away every unsaved change

**GitEasy**
```powershell
Undo-Changes -Force
```

**Plain Git**
```bash
git checkout -- .                # undo edits to known files
git clean -fd                    # also delete new files and folders
```

> GitEasy makes you add `-Force` (or `-Confirm`) before it will run.
> Plain Git deletes your work the second you press Enter.

## 12. Start a new working area

**GitEasy**
```powershell
New-WorkBranch feature-search-history
```

**Plain Git**
```bash
git check-ref-format --branch feature-search-history   # is the name valid?
git rev-parse --verify --quiet refs/heads/feature-search-history  # does it exist?
git checkout -b feature-search-history                 # make it and switch
```

## 13. Switch to another working area you already made

**GitEasy**
```powershell
Switch-Work feature-search-history
```

**Plain Git**
```bash
git status --porcelain=v1                       # is the folder clean first?
git checkout feature-search-history             # switch
```

> GitEasy refuses the switch if you would lose unsaved work. Plain Git
> tries anyway and may leave you with a hard-to-read error.

## 14. Show or delete junk files

**GitEasy**
```powershell
Clear-Junk            # show what would be deleted
Clear-Junk -Force     # actually delete
```

**Plain Git**
```bash
git clean -n -d       # show only (dry run)
git clean -f -d       # actually delete
```

> The plain Git `-n` / `-f` toggle is one keystroke away from disaster.
> `Clear-Junk` makes "show only" the default and "delete" the choice you
> have to make on purpose.

---

## What you do not see — the safety net

Every GitEasy command also does work that plain Git does not give you for
free:

- **Busy check.** It refuses to run while a merge, replay, cherry-pick,
  revert, or bisect is half done.
- **Conflict check.** If two saves clash, it lists the file names that
  need a person to look at them.
- **Login cleanup.** Usernames, passwords, and IP addresses are removed
  before anything is written to a log file.
- **Plain-English errors.** You never see raw Git output. The full tech
  detail goes to a dated log file at `%LOCALAPPDATA%\GitEasy\Logs` and
  logs older than 30 days delete themselves.
- **Tidy return values.** Every command gives back a small data object
  another script can use.

To get all of that yourself, you would have to write your own wrapper.
That wrapper is GitEasy.

---

## For Git experts: where to look under the hood

If you know Git and you want to inspect what GitEasy is doing, here is
where to look.

### Read the log files

```powershell
Show-Diagnostic                                    # open the most recent log
Show-Diagnostic -List                              # list recent logs
explorer $env:LOCALAPPDATA\GitEasy\Logs            # open the logs folder
```

Each log is one text file for one command run. Inside you will see the
parameters you ran, every `git` call made, the exit code for each,
sanitized output, and the final result. Tokens, usernames, and IPs are
redacted before they are written.

Point one run at a custom folder:

```powershell
Save-Work 'test save' -LogPath 'C:\Temp\GitEasyLogs'
```

Or set it system-wide with `GITEASY_LOG_PATH`.

### Read the source

The mapping is one-to-one and lives in the repo:

```text
Public/                # every user-facing command, one file each
Private/Invoke-GEGit.ps1   # the single place that runs git.exe
```

To answer "what exact Git command did GitEasy run?", open the matching
`Public/<Command>.ps1` and grep for `Invoke-GEGit -ArgumentList @(...)`.

### Run Git directly in the same folder

GitEasy never hides the underlying repository. After any GitEasy command
you can run normal Git:

```powershell
git status
git log --oneline -n 10
git reflog
git diff HEAD~1
```

The `.git` folder is untouched. There is no hidden state.

### Preview without changing anything

Most commands support `-WhatIf` and `-Confirm`:

```powershell
Save-Work 'try this out' -WhatIf
Undo-Changes -WhatIf
```

---

## Limitations

GitEasy is small on purpose. Here is what it will **not** do.

- **Windows-first.** Built and tested on Windows PowerShell 5.1 and
  PowerShell 7+ on Windows. Mac and Linux PowerShell *may* work, but
  are not tested.
- **Git must already be on your computer.** GitEasy does not install Git.
- **No automatic conflict fixing.** When two saves clash, GitEasy stops
  with a friendly message and lists the files. A person must open them
  and fix the conflict.
- **Only one online home, named `origin`.** If your project pushes to
  several places, you must do those pushes with plain Git.
- **No history editing.** No rebase, amend, squash, or cherry-pick. Saves
  are append-only. To rewrite history, use plain Git.
- **No advanced Git features.** No submodules, no worktrees, no bisect,
  no signed commits, no large file storage (LFS). Use plain Git if you
  need these.
- **One project folder at a time.** Commands act on the folder you are
  currently in.
- **Not yet on PowerShell Gallery.** You install by copying or cloning
  the folder yourself.
- **English only.** Every message is in English.
- **Windows login helpers only.** The login keepers GitEasy understands
  are the ones that ship with Git for Windows.

---

## The bottom line

| Thing | GitEasy | Plain Git |
|---|---|---|
| Commands to learn for daily work | **5** | 10+ |
| Key presses for save and publish | ~22 | ~85 |
| Commands that stop safely on bad input | All | Few |
| Output you must read to understand | None — plain English | All of it |
| Built-in log file | Yes | No, you write your own |

GitEasy is not a replacement for Git — Git still runs under it. GitEasy
is a replacement for the **20 commands and 4 traps** you used to have to
keep in your head to drive Git safely.

## See also

- [`HOW-TO-USE-GITEASY.md`](HOW-TO-USE-GITEASY.md) — full how-to guide.
- [`QUICKSTART.md`](QUICKSTART.md) — the shortest start.
- [`COMMAND_EXAMPLES.md`](COMMAND_EXAMPLES.md) — one example per command.
- `Get-Help <Command> -Full` — built-in help for any command.
