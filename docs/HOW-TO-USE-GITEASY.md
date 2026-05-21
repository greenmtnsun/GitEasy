# How to Use GitEasy

This is the easy-start guide to **GitEasy**, a tool that helps you save
your work without learning hard Git words.

Five commands for every day. Three commands you run once to set things
up. A few helper commands for when something goes wrong.

GitEasy uses plain words. You never see scary tech messages. If something
breaks, you get a short, friendly note and a path to a log file you can
share with a tech helper.

---

## Who this is for, and when it's the right tool

GitEasy is for people who need to **check in code** but do not want to
make Git their second job. That covers a lot more roles than "software
developer." This section is about whether GitEasy is the right tool for
you and what kinds of work it fits best.

### For first-time Git users

The first time you tried Git, you probably hit a wall of words: *stage,
commit, push, pull, fetch, rebase, upstream, HEAD, origin, branch, merge,
conflict, reflog*. GitEasy hides all of that. You learn five short
commands in plain English and that is enough to do real work. You will
never see a raw Git error message in GitEasy output. If something is
wrong, you get a one-line note and a path to a log file you can hand to a
tech helper.

### For Git experts — yes, this is for you too

If you already know Git well, GitEasy is **not** "training wheels you
grow out of." It is a thin, honest wrapper. You can keep your
`.gitconfig`, your `.git/hooks`, your aliases, and your editor
integrations. After any GitEasy command, you can drop into the same
folder and run `git status`, `git log --oneline`, `git reflog`,
`git diff HEAD~1` — nothing is hidden, nothing is changed behind your back, the
`.git` folder is untouched.

Three reasons an expert reaches for GitEasy:

- **One fewer chance to misspell.** Four muscle-memory commands collapse
  into one. Fewer keystrokes, no `git stsatus` retries.
- **A sanitized log of every Git call.** Every `git` invocation, its exit
  code, and its (scrubbed) output goes to
  `%LOCALAPPDATA%\GitEasy\Logs`. When something weird happens, the log
  answers "what exact Git command ran?" without you having to add
  `--verbose` flags.
- **A drop-in tool you can hand to a colleague who is not you.** When you
  onboard a junior, an analyst, or a sysadmin, you do not have to teach
  them Git. You teach `Save-Work`, `Find-CodeChange`, `Show-History`.
  They get the same safety you want for yourself.

If you ever want the raw layer for one operation, GitEasy never gets in
your way — `git.exe` is still installed and the same folder still works.

### Fields of work that fit GitEasy well

If you write or maintain files that change over time and you want a
trail of what changed and why, you can use GitEasy. A few concrete fits:

| Field | What you check in | Why GitEasy helps |
|---|---|---|
| **Sysadmin / IT operations** | PowerShell scripts, automation playbooks, scheduled-task definitions | One-command save before a risky change; rollback with `Restore-File`. |
| **Database administrator** | SQL migration scripts, stored procedures, backup-validation queries | Audit trail of what ran when, without learning rebase. |
| **DevOps / SRE** | Ansible roles, Terraform modules, CI YAML, runbooks | Solo or pair work where the simple flow saves time and the log file helps post-mortems. |
| **Compliance / audit** | Hardening evidence, control matrices, change attestations | Tamper-evident history; `Show-History -Count 30` answers "who changed what in the last month." |
| **Change manager / CAB chair** | Change request templates, post-implementation reviews, release notes | One folder, one history, simple read-only commands for evidence collection. |
| **Technical writer** | Knowledge-base articles, runbooks, training material | Drafting in plain Markdown with `Save-Work` gives you peer review for free. |
| **Power BI / Tableau developer** | DAX files, dataset metadata exports, dashboard JSON | Long sessions benefit from snapshot saves before each big change. |
| **Network engineer** | Router configs (Cisco IOS, FortiOS), firewall rule exports | A diff between versions answers "what changed in the firewall last Tuesday?" |

This is not the full list. The general principle: **if the file lives
on a filesystem and you want versioning plus an audit trail, GitEasy is
in scope.** It is only the wrong tool if your workflow lands on the
"unhappy path" below.

### Where GitEasy is the right fit

GitEasy is the right tool when most of these are true:

- You are working **solo or on a small team** (one to five people).
- Merge conflicts happen **sometimes**, not every day.
- You want **simple, append-only history** — saves stack on top of
  saves; you do not need to rewrite the past.
- You push to **one online home** (named `origin`).
- You are on **Windows** with PowerShell 5.1 or 7+.
- You want **a log of every Git call** without writing your own wrapper.

### Where GitEasy is the wrong fit

Honestly: there are workflows GitEasy will frustrate you on. Use a
different tool (or raw Git plus a Git GUI) if any of these describe
your day:

- **Ten or more people in the same folders with merge conflicts every
  day.** GitEasy stops on a conflict and asks a person to fix it. If
  five teammates every morning need to untangle yesterday's tree, you
  want a workflow with feature branches, pull requests, code review,
  and CI — none of which GitEasy automates. You can still *use* GitEasy
  on a busy team, but you lose its main payoff (one command does the
  right thing).
- **You need to rewrite history.** No rebase, no amend, no squash, no
  cherry-pick. If your team requires squash-on-merge or interactive
  rebase before push, GitEasy is the wrong layer.
- **Monorepo with submodules, worktrees, or sparse checkouts.** GitEasy
  does not know any of these are happening. Use raw Git for the
  structural commands; GitEasy is still fine for everyday saves *inside*
  a single worktree.
- **Large File Storage (LFS) or signed commits.** Not supported.
- **Multiple remotes.** GitEasy assumes one online home named `origin`.
  If you push to two different forges, do those pushes by hand.
- **Mac or Linux.** GitEasy is Windows-only today.

If two or more of those describe your day, GitEasy is a sidekick at
best. If none describe your day, GitEasy is probably the only Git tool
you need to teach a teammate.

---

## 1. Before you start (prerequisites)

You need:

- **Windows PowerShell 5.1** or **PowerShell 7+** (the blue or black
  PowerShell window).
- **Git** put on your computer. Type `git --version` to check. If you
  see a version number, you are good. If not, see section 2.
- A folder that is already a **project folder (a Git repository)**.
  An easy way to tell: it has a hidden folder named `.git` inside it.

## 2. Install Git on your computer (five ways)

GitEasy needs the **`git` program** on your computer. There are five
common ways to put it there on Windows. Pick **one**. They all give you
the same `git` underneath.

After any of them, open a fresh PowerShell window and run:

```powershell
git --version
```

You should see a version number like `git version 2.45.2.windows.1`. If
you see "command not found," restart PowerShell so it sees the new
`PATH`. If you still cannot see it, your PC's `PATH` is missing the Git
folder.

### 2.1 The official installer (recommended for most people)

The simplest way. Includes Git, the **login keeper (Git Credential
Manager)**, and a friendly setup wizard.

1. Open https://git-scm.com/download/win in a web browser.
2. Click the "64-bit Git for Windows Setup" link.
3. Run the downloaded `.exe`.
4. Click "Next" on every screen unless you have a reason to change a
   setting.
5. Reopen PowerShell. Run `git --version`.

### 2.2 winget (built into Windows 10 and 11)

If your PC has Windows 10 (newer) or Windows 11, **winget** is already
there. One line:

```powershell
winget install --id Git.Git -e --source winget
```

`-e` means "exact name." `--source winget` makes sure it pulls from the
official Microsoft list, not a side store.

### 2.3 Chocolatey (a Windows package helper)

If your machine already has **Chocolatey** (a tool that installs other
tools), this is the shortest path:

```powershell
choco install git -y
```

`-y` means "yes to all questions." If your machine does **not** have
Chocolatey, see https://chocolatey.org/install — but most people should
just use winget (section 2.2) instead.

### 2.4 Scoop (a per-user package helper)

**Scoop** installs tools into your own user folder. It needs no admin
rights. Good for locked-down work laptops.

```powershell
scoop install git
```

If you do not already have Scoop, see https://scoop.sh — again, most
people should use winget.

### 2.5 MinGit (the small, portable Git)

**MinGit** is a tiny zip-only build of Git. No installer. Just unzip
and use. Great for **air-gapped machines (computers with no internet)**
and locked-down work laptops where you cannot run installers.

1. On a connected machine, open
   https://github.com/git-for-windows/git/releases/latest in a browser.
2. Download the asset whose name starts with `MinGit-` and ends with
   `-64-bit.zip` (about 50 MB).
3. Copy the zip to the target machine on a USB stick or share.
4. Unzip it to a folder, for example `C:\Tools\MinGit`.
5. Add `C:\Tools\MinGit\cmd` to your `PATH`:

   ```powershell
   [Environment]::SetEnvironmentVariable(
     'Path',
     "$([Environment]::GetEnvironmentVariable('Path','User'));C:\Tools\MinGit\cmd",
     'User')
   ```

6. Open a new PowerShell window. Run `git --version`.

> MinGit does **not** include Git Credential Manager. For Git Credential
> Manager on an offline machine, download
> `gcm-win-x86_64-<version>.zip` from
> https://github.com/git-ecosystem/git-credential-manager/releases on a
> connected machine, copy it over, and unzip alongside MinGit.

### 2.6 What about Mac or Linux?

GitEasy is Windows-only today, so the steps above are Windows-only too.
On Mac, the normal way to put Git on the machine is `brew install git`.
On Linux, use your distro's package helper (`apt install git`,
`dnf install git`, etc.). Even with Git installed, the GitEasy commands
are not tested outside Windows — see section 10.

## 3. Install GitEasy (online and offline)

GitEasy is a **PowerShell module (a folder with PowerShell files in
it)**. You install it by putting that folder on your computer.

### 3.1 Online install (you have internet on the target machine)

The fastest way is to clone the GitHub project. Pick where you want it
to live and clone:

```powershell
New-Item -ItemType Directory -Path 'C:\Sysadmin\Scripts' -Force | Out-Null
Set-Location 'C:\Sysadmin\Scripts'
git clone https://github.com/greenmtnsun/GitEasy.git
```

You should now have a folder at `C:\Sysadmin\Scripts\GitEasy`.

Or, if you do not want to use `git clone`, download a zip:

1. Open https://github.com/greenmtnsun/GitEasy in a browser.
2. Click the green **Code** button, then **Download ZIP**.
3. Unzip it to `C:\Sysadmin\Scripts\GitEasy`.

### 3.2 Offline install (no internet on the target machine)

Use this when the target machine has no internet at all, or when
internet is blocked by company policy.

**On a machine that has internet:**

1. Open https://github.com/greenmtnsun/GitEasy in a browser.
2. Click the green **Code** button, then **Download ZIP**.
3. Save the zip file (something like `GitEasy-main.zip`) to a USB stick
   or a shared folder you can reach from the target machine.

**On the target machine (no internet):**

1. Copy the zip from the USB stick to the machine.
2. Right-click the zip → **Properties** → tick **Unblock** → **OK**.
   (Windows marks files from the internet as untrusted. This tells it
   the file is safe.)
3. Right-click the zip → **Extract All…** → extract to
   `C:\Sysadmin\Scripts\` so you end up with
   `C:\Sysadmin\Scripts\GitEasy` (or
   `C:\Sysadmin\Scripts\GitEasy-main` — rename the folder to
   `GitEasy`).
4. Open PowerShell and unblock every file inside the folder:

   ```powershell
   Get-ChildItem 'C:\Sysadmin\Scripts\GitEasy' -Recurse | Unblock-File
   ```

5. Check that PowerShell will let you run unsigned local files:

   ```powershell
   Get-ExecutionPolicy -Scope CurrentUser
   ```

   If it says `Restricted`, change it to `RemoteSigned` (only your user,
   not the whole machine):

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

6. Load the tool to be sure it works:

   ```powershell
   Import-Module 'C:\Sysadmin\Scripts\GitEasy\GitEasy.psd1' -Force
   Get-Command -Module GitEasy
   ```

### 3.3 What works offline and what does not

GitEasy works fine on a machine with no internet, **as long as** the
**online home (remote)** you point it at is reachable. That means:

| Setup | Works offline? |
|---|---|
| Saving locally with `Save-Work -NoPush` | **Yes.** |
| `Find-CodeChange`, `Show-History`, `Show-Remote` | **Yes.** |
| Pushing to an **internal** Git server (e.g., company-hosted GitLab, Gitea, or Azure DevOps Server on the same network) | **Yes.** |
| Pushing to `github.com`, `gitlab.com`, `bitbucket.org`, `dev.azure.com` | **No, you need internet for these.** |
| `Test-Login` against a host you cannot reach | **No, it will fail and tell you so.** |
| `git clone https://github.com/...` on the target machine | **No.** Clone on a connected machine first and copy the project folder over. |

### 3.4 Where to put the GitEasy folder

Anywhere is fine, as long as you give that path to `Import-Module`. The
common choices are:

- `C:\Sysadmin\Scripts\GitEasy` — a normal place for admin tools.
- One of your **PowerShell module paths** (so you can `Import-Module
  GitEasy` without typing the full path). To see those, run
  `$env:PSModulePath -split ';'`.

## 4. Load the tool (import the module)

Open PowerShell and run:

```powershell
Import-Module 'C:\Sysadmin\Scripts\GitEasy\GitEasy.psd1' -Force
Get-Command -Module GitEasy
```

The first line **loads (imports)** GitEasy so you can use it. `-Force`
means "reload it even if it is already there." The second line shows
every command GitEasy gives you so you can be sure it worked.

## 5. First-time setup

![First-time setup](images/first-time-setup.png)

Do these three things in order the first time you point GitEasy at a
project folder.

### 5.1 Tell GitEasy where your project lives online (set the remote)

```powershell
Set-Token -RemoteUrl 'https://github.com/<you>/<your-repo>.git'
```

This tells GitEasy the **online home (remote)** of your project. **Do not
put a password inside the address.** A safe helper on your computer (Git
Credential Manager) will ask you for your password when it needs it.

### 5.2 Pick where your login is kept (credential helper)

```powershell
Set-Vault -Helper manager
Get-VaultStatus
```

`Set-Vault -Helper manager` tells Git to use the **Windows password vault
(Git Credential Manager)**. `Get-VaultStatus` shows which helper is
picked.

### 5.3 Make sure your login works (test access)

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

### 5.4 Setup recipes for the top 5 Git hosts

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

## 6. Your daily steps

![Daily workflow](images/daily-workflow.png)

This is the small loop you do every day. **Five distinct commands**
walked through in six steps below — `Save-Work` shows up twice, once
for save-only (6.2) and once for save-and-publish (6.5).

### 6.1 See what you changed

```powershell
Find-CodeChange
```

Lists every file you changed, added, or have not yet saved. Run this
before you save so you know what is about to be saved.

### 6.2 Save a copy on your own computer (no online publish)

```powershell
Save-Work 'short note about what you did' -NoPush
```

`-NoPush` means "save a copy here only." Use this when you are in the
middle of a task and want a **safe rollback point (a checkpoint)**
before you go on.

### 6.3 See where your work will go online

```powershell
Show-Remote
```

Shows the online home of your project and which **working area (branch)**
you are on. Run this if you are not sure where your save is about to be
sent.

### 6.4 Check that your login still works

```powershell
Test-Login
```

A quick check before you publish. Cheaper than finding out your password
is out of date in the middle of a save.

### 6.5 Save and publish

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

### 6.6 Look back at your recent saves

```powershell
Show-History -Count 5
```

Shows the last five saved points with the date, who saved them, and the
short note. Change `-Count` to see more.

---

## Why one command instead of four — and what GitEasy guarantees

You have now run `Save-Work` once. Without `-NoPush`, it did four jobs in
one command:

1. Marked every changed file to be saved (`git add --all`).
2. Recorded a saved point (`git commit -m "your note"`).
3. Pulled down any new work from teammates (`git pull --rebase`).
4. Sent your work to the online home (`git push`).

If you came from raw Git, the natural question is: **am I losing
anything by letting one command do all four?**

The honest answer is **no**, and this section explains why.

### The thesis

Saving work to an online home is a *recipe*, not a choice. You almost
always want all four steps to happen, in that order, with sane defaults.
Raw Git makes you type each one because Git is a low-level tool that
does not assume what you want. GitEasy makes the safe assumption for
you.

What GitEasy does **not** do is hide the steps from you or change what
Git does underneath. Every one of the four `git` calls is logged,
exit-coded, and scrubbed of credentials in
`%LOCALAPPDATA%\GitEasy\Logs`. You can read exactly what ran, in what
order, with what arguments. Nothing is secret.

### What you get that raw Git does not give you for free

If you wrote your own wrapper around those four `git` calls, you would
also need to handle:

- **A half-done state.** What if a previous `git pull --rebase` left a
  half-resolved conflict and you forgot? Raw Git lets you stack a
  commit on top of that mess. GitEasy refuses to run and tells you to
  finish the rebase first.
- **A bad commit message.** Empty? All whitespace? Too long? GitEasy
  checks before it commits. Raw Git just commits.
- **A token in the URL.** If you set up a remote with
  `https://ghp_xxxxxx@github.com/...`, raw Git happily writes that into
  `.git/config` where it stays forever. GitEasy refuses any URL with
  credentials embedded.
- **A sanitized log.** Raw Git's output can include IPs, usernames, and
  (depending on the credential helper) sometimes tokens. GitEasy strips
  those before they are written to disk.
- **A clean return value.** Raw Git output is for humans. GitEasy
  returns a `[pscustomobject]` with `Passed`, `Pushed`, `BranchName`,
  `CommitMessage` that another script can consume.

All of that, in one command. That is the trade.

### "What if I want to do those steps separately?"

You still can. GitEasy never hides Git. After any GitEasy command, run
any normal Git inside the same folder:

```powershell
git add specific-file.ps1
git commit --amend
git push --force-with-lease
```

GitEasy is one wrapper layer; raw Git is still your friend underneath.
The two coexist. You can save with `Save-Work` on Monday and amend with
raw `git commit --amend` on Tuesday — same `.git/` folder, no conflict.

### What GitEasy promises you

Here is the explicit list of guarantees. If any of these break, that is
a bug — file it.

| Promise | What it means |
|---|---|
| **No data loss without your consent.** | Destructive commands (`Undo-Changes`, `Clear-Junk -Force`) require `-Force` or `-Confirm`. |
| **No secrets in logs.** | Tokens, passwords, usernames, and IPs are stripped from log lines before they are written to disk. |
| **No silent state changes.** | A half-done merge or rebase blocks GitEasy from running. You see the block. |
| **No surprises in `.git/config`.** | URLs with embedded credentials are refused. The on-disk config stays clean. |
| **No history rewrites.** | Saves are append-only. GitEasy never offers to rebase, squash, or amend. |
| **Same folder, same Git.** | The `.git/` folder is untouched. Raw Git commands work side-by-side. |
| **Every Git call is logged.** | One log file per command run. 30-day auto-cleanup. |

---

## 7. Command list

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

## 8. When something goes wrong

### 8.1 Bring back one file

```powershell
Restore-File README.md
```

Puts a single file back to the way it was at the last save. Your other
changed files are not touched.

### 8.2 Throw away every unsaved change

```powershell
Undo-Changes -Force
```

Deletes every change you have not saved. `-Force` is needed because this
cannot be undone. Use `-Confirm` if you want to be asked first.

### 8.3 Clean up junk files

```powershell
Clear-Junk        # show what would be deleted
Clear-Junk -Force # actually delete
```

### 8.4 Fix a bad saved login

```powershell
Reset-Login
Test-Login
```

`Reset-Login` tells the Windows password vault to forget your saved login
so it will ask you again next time.

### 8.5 Switch your project to use key-based login (SSH)

```powershell
Set-Ssh
Show-Remote
Test-Login
```

Only use this if you have already set up an **SSH key (a digital key
file)** with GitHub.

### 8.6 Open the log files

Every command writes a small log file (a record) at
`%LOCALAPPDATA%\GitEasy\Logs`. If a command worked, the log is silent. If
it failed, you get a short friendly note **plus** the path to the log.

```powershell
Show-Diagnostic         # open the most recent log
Show-Diagnostic -List   # list recent logs
Show-Diagnostic -All    # open the logs folder
```

Logs older than 30 days delete themselves.

## 9. Under the hood: where to inspect what GitEasy did

GitEasy is built for non-tech users, but everything it does is still
plain Git. If you know Git and you want to inspect what GitEasy did, you
have a few places to look. (See also the "For Git experts" framing
near the top of this guide for *why* you would want to use GitEasy at
all, even as an expert.)

### 9.1 The diagnostic log files

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

### 9.2 Read the source

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

### 9.3 Run Git directly in the same folder

GitEasy never hides the underlying repository. After any GitEasy command
you can run normal Git inside the same folder:

```powershell
git status
git log --oneline -n 10
git reflog
git diff HEAD~1
```

The `.git` folder is untouched. There is nothing magic on disk.

### 9.4 Test what GitEasy is about to do without changing anything

Most commands support PowerShell's `-WhatIf` and `-Confirm` because they
use `[CmdletBinding(SupportsShouldProcess)]`:

```powershell
Save-Work 'try this out' -WhatIf
Undo-Changes -WhatIf
```

`-WhatIf` shows you what would happen without doing it.

## 10. Limitations

Things GitEasy is **not** good for, on purpose:

- **It is built for Windows.** Windows PowerShell 5.1 and PowerShell 7+
  on Windows are the targets. PowerShell 7+ on Mac or Linux *may* work
  but is not tested.
- **It does not run on machines without Git.** Git must already be on
  your computer and on `PATH`. GitEasy will not install Git for you.
  (See section 2 for how to install Git, including an offline option.)
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
- **Offline use needs an offline online home.** GitEasy works fine on a
  machine with no internet, but `Save-Work` (without `-NoPush`) needs to
  be able to reach the online home you pointed it at. A real offline
  setup is an internal company Git server, not "no server at all."
- **English only.** Every message is in English.
- **Windows credential helpers only.** The login helpers GitEasy
  understands are the ones that ship with Git for Windows. On Mac or
  Linux you must set up your own helper.

## 11. A full example session

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

## 12. Where to go next

- `docs/QUICKSTART.md` — the shortest start.
- `docs/COMMAND_EXAMPLES.md` — one example per command.
- `docs/GITEASY-VS-RAW-GIT.md` — every GitEasy command shown next to the
  raw Git it replaces.
- `Examples/` — runnable PowerShell scripts numbered 00 through 10.
- `Get-Help <Command> -Full` — built-in help for any command.
- [GitEasy Wiki](https://github.com/greenmtnsun/GitEasy/wiki) — long
  reference, one page per command.

## 13. A short plain-English glossary

These are the Git words that show up most often in places GitEasy cannot
hide them (error messages, log files, the section above for experts).
Skim this once and you will be set.

| Word | What it means in plain English |
|---|---|
| **branch** | A working area inside a project. You can have several. GitEasy calls them "working areas." |
| **commit** | A saved point. A snapshot of your project at one moment, with a note attached. |
| **conflict** | Two saves disagree about the same line. A person has to pick which line stays. |
| **HEAD** | Git's name for the most recent saved point you are sitting on. |
| **log** | A list of recent saved points, newest first. |
| **origin** | The default name for your online home (your project's address on GitHub, GitLab, etc.). |
| **pull** | Bring down new work from teammates into your folder. |
| **push** | Send your saved work up to the online home. |
| **rebase** | Move your saves on top of a teammate's saves. GitEasy does the safe version of this for you (`pull --rebase`); it never asks you to drive it by hand. |
| **remote** | The online home of your project. GitEasy uses "online home" everywhere. |
| **repository (repo)** | A folder with a hidden `.git` inside it. Your project folder. |
| **stage** | Mark a changed file as "I want this to be in the next save." GitEasy does this for you on `Save-Work`. |
| **amend / squash / cherry-pick** | Three ways to **rewrite history** in raw Git. GitEasy does **not** do these on purpose — saves are append-only. |
| **upstream** | The link between your working area and the online home. GitEasy sets this up with `Save-Work -SetUpstream` the first time you publish. |
| **submodule / worktree / sparse checkout / LFS** | Advanced Git features GitEasy does not support. If you do not know what these are, you do not need them. |
