# GitEasy vs Raw Git: Side-by-Side

A walkthrough of every common Git task. For each one you see what **you
type with GitEasy** and what you would have typed with **raw Git** to do
the same job. The point is not that Git is wrong — it is that GitEasy
collapses 2–5 careful Git steps into one plain-English command.

> All Raw Git columns below are the actual `git` invocations GitEasy runs
> under the hood (pulled straight from the module source). Nothing is
> exaggerated — these are the commands you would have to remember,
> sequence, and get right yourself.

A visual one-pager of this comparison lives in Canva:
**https://www.canva.com/d/2KuZnXt2Wo9RJ3D**
(Export as PNG and drop into `docs/images/giteasy-vs-raw-git.png` to embed
inline.)

---

## At a glance

| Task | GitEasy (1 command) | Raw Git (steps) |
|---|---|---|
| Save and publish | `Save-Work 'msg'` | 4 |
| Local-only checkpoint | `Save-Work 'msg' -NoPush` | 2 |
| See what changed | `Find-CodeChange` | 3 |
| Show recent history | `Show-History -Count 5` | 1 (with cryptic flags) |
| Show where you publish | `Show-Remote` | 2 |
| Verify login | `Test-Login` | 2 |
| Configure HTTPS remote | `Set-Token -RemoteUrl '…'` | 1 (and easy to misuse) |
| Switch remote to SSH | `Set-Ssh` | 1–2 + URL editing |
| Forget cached credential | `Reset-Login` | 2–3 |
| Restore one file | `Restore-File path` | 2 |
| Throw away all changes | `Undo-Changes -Force` | 2 |
| New working branch | `New-WorkBranch name` | 2 |
| Switch working branch | `Switch-Work name` | 1 (after status check) |
| Clear junk files | `Clear-Junk -Force` | 2 |

---

## 1. Save and publish a change

The flagship comparison. With raw Git you have to stage, commit, fetch
peer changes, rebase, then push — five concepts and four commands. With
GitEasy it is one verb.

**GitEasy**
```powershell
Save-Work 'fix readme'
```

**Raw Git**
```bash
git add --all
git commit -m "fix readme"
git pull --rebase
git push
```

If the branch has no upstream yet:

**GitEasy**
```powershell
Save-Work 'first remote checkpoint' -SetUpstream
```

**Raw Git**
```bash
git add --all
git commit -m "first remote checkpoint"
git push -u origin <branch-name>     # you must know the branch name
```

> GitEasy also refuses to run inside an unfinished merge / rebase /
> cherry-pick / revert / bisect, validates the message, and writes a
> diagnostic log. Raw Git happily lets you stack a bad commit on top of
> a half-resolved rebase.

## 2. Local-only checkpoint (no push)

**GitEasy**
```powershell
Save-Work 'checkpoint before refactor' -NoPush
```

**Raw Git**
```bash
git add --all
git commit -m "checkpoint before refactor"
```

## 3. See what changed

GitEasy gives you one composite view. Raw Git makes you remember three
separate views (staged, unstaged, untracked) and stitch them in your head.

**GitEasy**
```powershell
Find-CodeChange
```

**Raw Git**
```bash
git status --short --untracked-files=normal
git diff --stat
git diff --cached --stat
```

## 4. Show recent history

The raw Git form is technically one command — but it is one command no
human remembers.

**GitEasy**
```powershell
Show-History -Count 5
```

**Raw Git**
```bash
git log --max-count=5 --date=short \
  --pretty=format:%h%x09%ad%x09%an%x09%s
```

## 5. Show where you publish

**GitEasy**
```powershell
Show-Remote
```

**Raw Git**
```bash
git remote -v
git symbolic-ref --short HEAD     # plus this to know your branch
```

## 6. Verify login / connectivity to the remote

**GitEasy**
```powershell
Test-Login
```

**Raw Git**
```bash
git remote
git ls-remote --heads origin
```

> GitEasy also returns a structured `Passed = True/False` result you can
> drop into a script. Raw Git makes you parse output.

## 7. Configure an HTTPS remote

**GitEasy**
```powershell
Set-Token -RemoteUrl 'https://github.com/you/repo.git'
```

**Raw Git** (adding a new remote)
```bash
git remote add origin https://github.com/you/repo.git
```

**Raw Git** (updating an existing remote)
```bash
git remote set-url origin https://github.com/you/repo.git
```

> GitEasy picks `add` vs `set-url` for you, **rejects URLs with embedded
> credentials** like `https://token@host/…` so secrets never get committed
> to a config file, and recommends Git Credential Manager. Raw Git lets
> you paste a token straight into config and forget about it.

## 8. Switch the remote to SSH

**GitEasy**
```powershell
Set-Ssh
```

**Raw Git**
```bash
git remote -v                                        # find the HTTPS URL
git remote set-url origin git@github.com:you/repo.git
```

> GitEasy does the URL rewrite for you — including stripping the
> `https://`, the host swap, and the trailing `.git` handling.

## 9. Forget a bad cached HTTPS credential

This is the one that bites everyone. The raw Git incantation is genuinely
obscure.

**GitEasy**
```powershell
Reset-Login
```

**Raw Git** (one of several variants, depending on which credential helper
is configured)
```bash
printf "protocol=https\nhost=github.com\n\n" | git credential reject
printf "protocol=https\nhost=github.com\n\n" | git credential-manager erase
git config --global --get credential.helper       # to know which to call
```

> GitEasy also clears matching `cmdkey` entries on Windows. Raw Git
> requires you to know to do this separately.

## 10. Restore one file

**GitEasy**
```powershell
Restore-File README.md
```

**Raw Git**
```bash
git ls-files --error-unmatch -- README.md     # confirms the file is tracked
git checkout -- README.md
```

## 11. Throw away every unsaved change

**GitEasy**
```powershell
Undo-Changes -Force
```

**Raw Git**
```bash
git checkout -- .
git clean -fd
```

> GitEasy requires `-Force` (or `-Confirm`) before it will run. Raw Git
> deletes your work the instant you hit Enter.

## 12. Start a new working branch

**GitEasy**
```powershell
New-WorkBranch feature-search-history
```

**Raw Git**
```bash
git check-ref-format --branch feature-search-history     # validate name
git rev-parse --verify --quiet refs/heads/feature-search-history
git checkout -b feature-search-history
```

## 13. Switch to another existing working branch

**GitEasy**
```powershell
Switch-Work feature-search-history
```

**Raw Git**
```bash
git status --porcelain=v1                       # check tree is clean first
git checkout feature-search-history
```

> GitEasy refuses the switch if uncommitted work would be lost. Raw Git
> happily tries it and may leave you with a confusing error message.

## 14. List or clear junk files

**GitEasy**
```powershell
Clear-Junk            # list what would be removed
Clear-Junk -Force     # actually remove
```

**Raw Git**
```bash
git clean -n -d       # dry-run preview
git clean -f -d       # actually remove
```

> The raw Git `-n` / `-f` toggle is one keystroke from disaster.
> `Clear-Junk` makes preview the default and removal explicit.

---

## What you do not see — the safety scaffolding

Every GitEasy public command also does work that no raw Git incantation
gives you for free:

- **Repository busy check** — refuses to run while a merge, rebase,
  cherry-pick, revert, or bisect is in progress.
- **Unfinished-conflict check** — lists files that need attention by name.
- **Credential scrubbing** — usernames, tokens, and IPv4 addresses are
  redacted before anything is written to a log.
- **Plain-English errors** — no raw Git stderr ever reaches the user; the
  full technical output goes to a dated log under
  `%LOCALAPPDATA%\GitEasy\Logs` and old logs auto-prune after 30 days.
- **Structured return values** — every command returns an object you can
  pipe, filter, or test in a script.

To reproduce those guarantees with raw Git you would write your own
wrapper. That wrapper is GitEasy.

---

## The bottom line

| Measure | GitEasy | Raw Git |
|---|---|---|
| Commands to learn for daily work | **5** (`Find-CodeChange`, `Save-Work`, `Show-History`, `Show-Remote`, `Test-Login`) | 10+ |
| Average keystrokes per save-and-publish | ~22 | ~85 |
| Commands that fail safely on bad input | All | Few |
| Output you have to mentally parse | None — plain English | All of it |
| Diagnostic logging | Built in | Roll your own |

GitEasy is not a replacement for Git — Git still runs underneath. GitEasy
is a replacement for the **20 commands and 4 footguns** you used to have
to keep in your head to drive Git safely.

## See also

- [`HOW-TO-USE-GITEASY.md`](HOW-TO-USE-GITEASY.md) — full how-to guide.
- [`QUICKSTART.md`](QUICKSTART.md) — minimum-keystrokes intro.
- [`COMMAND_EXAMPLES.md`](COMMAND_EXAMPLES.md) — one example per command.
- `Get-Help <Command> -Full` — comment-based help on any public command.
