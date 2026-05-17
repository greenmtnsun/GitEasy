# GitEasy V2 Examples

Run these examples from PowerShell.

Start here (from the repository root):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Examples\00-State-Check.ps1
```

Each script derives the project root from its own location, so no path
argument is needed when run from inside a GitEasy checkout. Override with
`-ProjectRoot <path>` only if running a script copied elsewhere.

Recommended order:

1. 00-State-Check.ps1
2. 01-Import-And-List-Commands.ps1
3. 02-Show-Current-Repository.ps1
4. 03-Check-Remote-And-Login.ps1
5. 04-Save-Local-Only.ps1
6. 05-Configure-GitHub-Https.ps1
7. 06-Use-GitHub-Credential-Manager.ps1
8. 07-Switch-To-Ssh.ps1
9. 08-Reset-Bad-Login.ps1
10. 09-Daily-Workflow.ps1
11. 10-Confirm-Install.ps1
