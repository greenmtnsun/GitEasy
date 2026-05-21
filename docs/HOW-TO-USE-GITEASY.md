# How to Use GitEasy

This is the easy-start guide to **GitEasy**, a tool that helps you save
your work without learning hard Git words.

Five commands for every day. Three commands you run once to set things
up. A few helper commands for when something goes wrong.

GitEasy uses plain words. You never see scary tech messages. If something
breaks, you get a short, friendly note and a path to a log file you can
share with a tech helper.

---

## Pictures that go with this guide

I made three pictures in Canva to go with this guide. The links open the
pictures in Canva. To make them show up inside this page, save each one
as a PNG file and put it in the `docs/images/` folder.

| Picture | What it shows | Canva link | File name |
|---|---|---|---|
| 1 | First-time setup | https://www.canva.com/d/ZeajQux9lX2yMKP | `docs/images/first-time-setup.png` |
| 2 | Your daily steps | https://www.canva.com/d/lzVDVWdVfdDutV4 | `docs/images/daily-workflow.png` |
| 3 | Quick command card | https://www.canva.com/d/TYMcRP3_CVNpmwL | `docs/images/command-reference.png` |

---

## 1. Before you start (prerequisites)

You need:

- **Windows PowerShell 5.1** or **PowerShell 7+** (the blue or black
  PowerShell window).
- **Git** put on your computer. Type `git --version` to check. If you
  see a version number, you are good.
- A folder that is already a **project folder (a Git repository)**.
  An easy way to tell: it has a hidden folder named `.git` inside it.

## 2. Load the tool (import the module)

Open PowerShell and run:

```powershell
Import-Module 'C:\Sysadmin\Scripts\GitEasy\GitEasy.psd1' -Force
Get-Command -Module GitEasy
```

The first line **loads (imports)** GitEasy so you can use it. `-Force`
means "reload it even if it is already there." The second line shows
every command GitEasy gives you so you can be sure it worked.

## 3. First-time setup

![First-time setup](images/first-time-setup.png)

Do these three things in order the first time you point GitEasy at a
project folder.

### 3.1 Tell GitEasy where your project lives online (set the remote)

```powershell
Set-Token -RemoteUrl 'https://github.com/<you>/<your-repo>.git'
```

This tells GitEasy the **online home (remote)** of your project. **Do not
put a password inside the address.** A safe helper on your computer (Git
Credential Manager) will ask you for your password when it needs it.

### 3.2 Pick where your login is kept (credential helper)

```powershell
Set-Vault -Helper manager
Get-VaultStatus
```

`Set-Vault -Helper manager` tells Git to use the **Windows password vault
(Git Credential Manager)**. `Get-VaultStatus` shows which helper is
picked.

### 3.3 Make sure your login works (test access)

```powershell
Test-Login
```

A good result looks like this:

```text
Passed  : True
Message : Remote login/connectivity test passed.
```

If you see `Passed : False`, run `Show-Diagnostic` to open the most recent
**log file (a file that lists what just happened, step by step)**.

### 3.4 Setup recipes for the top 5 Git hosts

**Good news:** the three GitEasy commands you run (`Set-Token`,
`Set-Vault`, `Test-Login`) are the **same on every host**. The only
things that change from host to host are:

1. The **shape of the online address (URL)** you give to `Set-Token`.
2. Where you go on that host's website to make a **password code
   (personal access token / app password)**.

The login keeper (Git Credential Manager) supports all of these
out of the box on Windows. You do not need a different `Set-Vault`
setting for each one.

#### 1. GitHub

The most common host. GitEasy was first tested on GitHub.

```powershell
Set-Token -RemoteUrl 'https://github.com/<you>/<your-repo>.git'
Set-Vault  -Helper manager
Test-Login
```

- **Address shape:** `https://github.com/<owner>/<repo>.git`
- **Password code:** a *Personal Access Token (PAT)*. Make one at
  **github.com → Settings → Developer settings → Personal access
  tokens**. Give it the `repo` scope.
- **What you paste:** when Git Credential Manager pops up, use your
  GitHub user name and **paste the token where it asks for a password**.
- **Notes:** GitHub no longer accepts your real password for Git over
  the web. The token is the password now.

#### 2. GitLab (gitlab.com or your own GitLab server)

```powershell
Set-Token -RemoteUrl 'https://gitlab.com/<you>/<your-repo>.git'
Set-Vault  -Helper manager
Test-Login
```

For a self-hosted GitLab, swap `gitlab.com` for your company host:

```powershell
Set-Token -RemoteUrl 'https://gitlab.example.com/<group>/<repo>.git'
```

- **Address shape:** `https://<gitlab-host>/<group-or-user>/<repo>.git`
- **Password code:** a *Personal Access Token*. Make one at
  **GitLab → User Settings → Access Tokens**. Give it at least
  `write_repository` scope.
- **What you paste:** any user name (or `oauth2`) and the token as the
  password.
- **Notes:** Self-hosted GitLab works the same as gitlab.com. Only the
  host name changes.

#### 3. Bitbucket Cloud (Atlassian)

```powershell
Set-Token -RemoteUrl 'https://bitbucket.org/<workspace>/<your-repo>.git'
Set-Vault  -Helper manager
Test-Login
```

- **Address shape:** `https://bitbucket.org/<workspace>/<repo>.git`
  (note: workspace, not user)
- **Password code:** an *App Password*. Make one at **Bitbucket → Your
  avatar → Personal settings → App passwords**. Tick the
  `Repositories: Read` and `Repositories: Write` boxes.
- **What you paste:** your Bitbucket user name (not your email) and the
  app password as the password.
- **Notes:** Bitbucket calls the password code an *App Password*, not a
  token. Bitbucket has not taken plain account passwords over Git since
  2022.

#### 4. Azure DevOps (Azure Repos, by Microsoft)

```powershell
Set-Token -RemoteUrl 'https://dev.azure.com/<org>/<project>/_git/<your-repo>'
Set-Vault  -Helper manager
Test-Login
```

- **Address shape:**
  `https://dev.azure.com/<org>/<project>/_git/<repo>` — there is **no
  `.git` on the end** like GitHub, and the path has the extra
  `<project>/_git/` chunk.
- **Password code:** a *Personal Access Token (PAT)*. Make one at
  **Azure DevOps → User Settings (top right) → Personal access tokens**.
  Give it the **Code (Read & Write)** scope.
- **What you paste:** any user name (you can leave it blank or type
  anything) and the PAT as the password.
- **Notes:** Git Credential Manager has special built-in support for
  Azure DevOps and will offer to open a browser to sign you in. That is
  normal.

#### 5. Gitea (the popular self-hosted Git server)

If you (or your company) runs your own Git server, it is most often
Gitea. The set-up is the same shape as gitlab.com.

```powershell
Set-Token -RemoteUrl 'https://git.example.com/<you>/<your-repo>.git'
Set-Vault  -Helper manager
Test-Login
```

- **Address shape:** `https://<your-gitea-host>/<owner>/<repo>.git`
- **Password code:** an *Access Token*. Make one at **Your Gitea
  site → Settings → Applications → Generate New Token**.
- **What you paste:** your Gitea user name and the token as the
  password.
- **Notes:** Gitea looks like a generic Git host to Git Credential
  Manager. No special setup is needed.

#### Quick lookup table

| Host | Address shape | Password code is called | Where to make it |
|---|---|---|---|
| GitHub | `https://github.com/<owner>/<repo>.git` | Personal Access Token | Settings → Developer settings → Personal access tokens |
| GitLab | `https://gitlab.com/<owner>/<repo>.git` (or self-host) | Personal Access Token | User Settings → Access Tokens |
| Bitbucket | `https://bitbucket.org/<workspace>/<repo>.git` | App Password | Personal settings → App passwords |
| Azure DevOps | `https://dev.azure.com/<org>/<project>/_git/<repo>` | Personal Access Token | User Settings → Personal access tokens |
| Gitea | `https://<your-host>/<owner>/<repo>.git` | Access Token | Settings → Applications |

#### What does **not** change across hosts

To be very clear about what stays the same:

- The three GitEasy commands (`Set-Token`, `Set-Vault`, `Test-Login`)
  are exactly the same.
- The Windows login keeper (`-Helper manager`) is the same.
- The advice "**never put the password code inside the address**" is
  the same. `Set-Token` refuses any address with credentials baked in
  on every host.
- `Save-Work`, `Find-CodeChange`, `Show-History`, and the rest do not
  know or care which host you use.
- The day-to-day pop-up from Git Credential Manager is the same shape:
  user name on top, password code on the bottom.

## 4. Your daily steps

![Daily workflow](images/daily-workflow.png)

This is the small loop you do every day. Five commands, in order.

### 4.1 See what you changed

```powershell
Find-CodeChange
```

Lists every file you changed, added, or have not yet saved. Run this
before you save so you know what is about to be saved.

### 4.2 Save a copy on your own computer (no online publish)

```powershell
Save-Work 'short note about what you did' -NoPush
```

`-NoPush` means "save a copy here only." Use this when you are in the
middle of a task and want a **safe rollback point (a checkpoint)**
before you go on.

### 4.3 See where your work will go online

```powershell
Show-Remote
```

Shows the online home of your project and which **working area (branch)**
you are on. Run this if you are not sure where your save is about to be
sent.

### 4.4 Check that your login still works

```powershell
Test-Login
```

A quick check before you publish. Cheaper than finding out your password
is out of date in the middle of a save.

### 4.5 Save and publish

```powershell
Save-Work 'short note about what you did'
```

Without `-NoPush`, `Save-Work` does four jobs in one:

1. **Marks every changed file to be saved (stages them).**
2. **Records a saved point (a commit).**
3. **Pulls down any new work from your teammates (pull).**
4. **Sends your work to the online home (push).**

#### First time you publish a new working area

```powershell
Save-Work 'first online save' -SetUpstream
```

`-SetUpstream` sets up the link between your computer and the online
home so future saves know where to go.

#### Bump the version number while you save

```powershell
Save-Work 'Add new search command' -BumpVersion -BumpKind Minor
```

Bumps the version number in your `.psd1` **file (a small file that
describes a PowerShell module)** and puts the new number at the start of
your saved-point note.

### 4.6 Look back at your recent saves

```powershell
Show-History -Count 5
```

Shows the last five saved points with the date, who saved them, and the
short note. Change `-Count` to see more.

## 5. Command list

![Command reference card](images/command-reference.png)

| Command | What it does |
|---|---|
| `Find-CodeChange` | Lists what you changed in your project folder. |
| `Save-Work` | Saves your work and sends it online (or `-NoPush` to save only on your computer). |
| `Show-History` | Shows your last few saved points. |
| `Show-Remote` | Shows where your project goes online. |
| `Show-Diagnostic` | Opens or lists the log files (a record of what GitEasy did). |
| `New-WorkBranch` | Starts a new working area for a side task. |
| `Switch-Work` | Jumps to a different working area you already made. |
| `Restore-File` | Brings one file back to the way it was at the last save. |
| `Undo-Changes` | Throws away your unsaved work (you must add `-Force` or `-Confirm`). |
| `Clear-Junk` | Lists or deletes plain junk files. |
| `Test-Login` | Checks that your online login works. |
| `Set-Token` | Sets up a normal-web (HTTPS) login. |
| `Set-Ssh` | Sets up a key-based (SSH) login. |
| `Set-Vault` | Picks where your saved login is kept. |
| `Get-VaultStatus` | Shows which login keeper is being used. |
| `Reset-Login` | Forgets the saved login so you can put in a new one. |

Every command has a built-in help page:

```powershell
Get-Help Save-Work -Full
Get-Help Save-Work -Examples
```

## 6. When something goes wrong

### 6.1 Bring back one file

```powershell
Restore-File README.md
```

Puts a single file back to the way it was at the last save. Your other
changed files are not touched.

### 6.2 Throw away every unsaved change

```powershell
Undo-Changes -Force
```

Deletes every change you have not saved. `-Force` is needed because this
cannot be undone. Use `-Confirm` if you want to be asked first.

### 6.3 Clean up junk files

```powershell
Clear-Junk        # show what would be deleted
Clear-Junk -Force # actually delete
```

### 6.4 Fix a bad saved login

```powershell
Reset-Login
Test-Login
```

`Reset-Login` tells the Windows password vault to forget your saved login
so it will ask you again next time.

### 6.5 Switch your project to use key-based login (SSH)

```powershell
Set-Ssh
Show-Remote
Test-Login
```

Only use this if you have already set up an **SSH key (a digital key
file)** with GitHub.

### 6.6 Open the log files

Every command writes a small log file (a record) at
`%LOCALAPPDATA%\GitEasy\Logs`. If a command worked, the log is silent. If
it failed, you get a short friendly note **plus** the path to the log.

```powershell
Show-Diagnostic         # open the most recent log
Show-Diagnostic -List   # list recent logs
Show-Diagnostic -All    # open the logs folder
```

Logs older than 30 days delete themselves.

## 7. For Git experts: where to look under the hood

GitEasy is built for non-tech users, but everything it does is still
plain Git. If you know Git and you want to inspect what GitEasy did, you
have a few places to look.

### 7.1 The diagnostic log files

```powershell
# Open the most recent log:
Show-Diagnostic

# Or jump straight to the folder:
explorer $env:LOCALAPPDATA\GitEasy\Logs
```

Each log is a single text file for one command run. Inside you will see:

- The command that was run and its parameters.
- Every `git` call GitEasy made, in order, with the exit code.
- Sanitized output. **Usernames, tokens, and IP addresses are removed
  before they are written to disk.**
- The final result the command returned.

This is the fastest way for a Git expert to answer "what did GitEasy
actually do?"

You can also point GitEasy at a different log folder for one run:

```powershell
Save-Work 'test save' -LogPath 'C:\Temp\GitEasyLogs'
```

Or change it system-wide with the `GITEASY_LOG_PATH` environment
variable.

### 7.2 Read the source

Every public command is one PowerShell file:

```text
GitEasy/
  Public/                # every user-facing command
  Private/               # internal helpers, including Invoke-GEGit
```

`Private/Invoke-GEGit.ps1` is the single place that runs `git.exe`.
If you want to know "what exact `git` command did GitEasy run?", search
the `Public/*.ps1` file for the command name and look at every
`Invoke-GEGit -ArgumentList @(...)` call.

For a side-by-side mapping of every GitEasy command to its real Git
commands, see [`GITEASY-VS-RAW-GIT.md`](GITEASY-VS-RAW-GIT.md).

### 7.3 Run Git directly in the same folder

GitEasy never hides the underlying repository. After any GitEasy command
you can run normal Git inside the same folder:

```powershell
git status
git log --oneline -n 10
git reflog
git diff HEAD~1
```

The `.git` folder is untouched. There is nothing magic on disk.

### 7.4 Test what GitEasy is about to do without changing anything

Most commands support PowerShell's `-WhatIf` and `-Confirm` because they
use `[CmdletBinding(SupportsShouldProcess)]`:

```powershell
Save-Work 'try this out' -WhatIf
Undo-Changes -WhatIf
```

`-WhatIf` shows you what would happen without doing it.

## 8. Limitations

Things GitEasy is **not** good for, on purpose:

- **It is built for Windows.** Windows PowerShell 5.1 and PowerShell 7+
  on Windows are the targets. PowerShell 7+ on Mac or Linux *may* work
  but is not tested.
- **It does not run on machines without Git.** Git must already be on
  your computer and on `PATH`. GitEasy will not install Git for you.
- **It does not solve merge conflicts for you.** If two saves change the
  same line, GitEasy stops and tells you a plain-English message. You
  (or a tech helper) must open the file and fix the conflict before
  saving again.
- **It does not handle every Git workflow.** It will not do
  `git submodule`, `git worktree`, `git bisect`, signed commits, or
  large file storage (LFS). If you need any of those, run Git directly.
- **It assumes one online home named `origin`.** If your project pushes
  to several places, you must do those pushes with raw Git.
- **It does not edit history.** No rebase, amend, squash, or
  cherry-pick. Saves are append-only. If you need to rewrite history,
  use Git directly.
- **One project folder per session.** `Save-Work` and friends work on
  the folder you are currently in. Run them from inside the project you
  want to change.
- **Not on PowerShell Gallery yet.** You install GitEasy by copying or
  cloning the folder yourself. There is no `Install-Module` from the
  online gallery yet.
- **English only.** Every message is in English.
- **Windows credential helpers only.** The login helpers GitEasy
  understands are the ones that ship with Git for Windows. On Mac or
  Linux you must set up your own helper.

## 9. A full example session

```powershell
# Load the tool.
Set-Location C:\Sysadmin\Scripts\GitEasy
Import-Module .\GitEasy.psd1 -Force

# What did I change today?
Find-CodeChange

# Take a safe checkpoint before I rearrange things.
Save-Work 'checkpoint before refactor' -NoPush

# Rearrange your files in your editor, then look again.
Find-CodeChange

# Make sure I know where this is going.
Show-Remote
Test-Login

# Save and publish.
Save-Work 'Tidy up the public commands'

# Confirm the save landed.
Show-History -Count 3
```

## 10. Where to go next

- `docs/QUICKSTART.md` — the shortest start.
- `docs/COMMAND_EXAMPLES.md` — one example per command.
- `docs/GITEASY-VS-RAW-GIT.md` — every GitEasy command shown next to the
  raw Git it replaces.
- `Examples/` — runnable PowerShell scripts numbered 00 through 10.
- `Get-Help <Command> -Full` — built-in help for any command.
- [GitEasy Wiki](https://github.com/greenmtnsun/GitEasy/wiki) — long
  reference, one page per command.
