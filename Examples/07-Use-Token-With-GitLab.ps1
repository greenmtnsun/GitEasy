# GitEasy example
# Scenario:
# Your GitLab remote uses HTTPS and your company expects a token.
#
# What to type when Git prompts:
#   Username: your GitLab username (or work email if your company uses that)
#   Password: your GitLab token

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

Show-Remote
Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"
Test-Login
Save-Work -Note "Test push with GitLab token"
