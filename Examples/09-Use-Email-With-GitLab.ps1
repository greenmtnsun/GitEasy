# GitEasy example
# Scenario:
# Your company may accept your email address as the GitLab username.
#
# What to type when Git prompts:
#   Username: you@company.com
#   Password: usually your GitLab token

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

Show-Remote
Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"
Reset-Login
Test-Login
Save-Work -Note "Test push using email address for GitLab login"
