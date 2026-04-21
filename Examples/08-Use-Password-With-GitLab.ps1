# GitEasy example
# Scenario:
# Your GitLab remote uses HTTPS and your company still allows normal login/password.
#
# What to type when Git prompts:
#   Username: your GitLab username, work login, or work email
#   Password: your normal GitLab password
#
# If you get 'HTTP Basic: Access denied', switch to the token example instead.

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

Show-Remote
Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"
Reset-Login
Test-Login
Save-Work -Note "Test push with GitLab password"
