# GitEasy example
# Scenario:
# You log into Windows with a smart card and PIN, but Git itself still needs a GitLab token.
#
# This is common at work.
# Smart card login may get you into Windows, VPN, browser, or SSO,
# but Git over HTTPS may still ask for GitLab credentials.
#
# What to type when Git prompts:
#   Username: your GitLab username or work email
#   Password: your GitLab token

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

# See the current remote.
Show-Remote

# Make sure the repo is using the HTTPS GitLab address.
Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"

# Clear old saved login so Git can ask again.
Reset-Login

# Test without pushing first.
Test-Login

# Push after the login test works.
Save-Work -Note "Test push from smart card workstation using GitLab token"
