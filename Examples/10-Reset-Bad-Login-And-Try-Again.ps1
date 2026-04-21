# GitEasy example
# Scenario:
# Git used to work, but now push fails because Windows likely saved a bad or old login.

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

Show-Remote
Reset-Login
Test-Login
Save-Work -Note "Retry after clearing saved Git login"
