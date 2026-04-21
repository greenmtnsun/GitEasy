# GitEasy example
# Scenario:
# You log into Windows with a smart card and PIN, but Git itself still needs a GitLab token.
#
# Smart card login may get you into Windows, VPN, browser, or SSO,
# but Git over HTTPS may still ask for GitLab credentials.
#
# What to type when Git prompts:
#   Username: your GitLab username or work email
#   Password: your GitLab token

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

Show-Remote
Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"
Reset-Login
Test-Login
Save-Work -Note "Test push from smart card workstation using GitLab token"
