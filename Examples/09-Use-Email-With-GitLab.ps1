# GitEasy example
# Scenario:
# Your company may accept your email address as the GitLab username.
#
# What to type when Git prompts:
#   Username: you@company.com
#   Password: usually your GitLab token
#
# Notes:
# - This script uses the normal HTTPS flow.
# - The difference is what YOU enter at the prompt.
# - Try GitLab username first if email does not work.

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

# See the current online address for this repo.
Show-Remote

# Make sure the repo is using the HTTPS GitLab address.
Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"

# Remove old saved login for this host.
Reset-Login

# Test access. When prompted, try your company email as the username.
Test-Login

# If the test works, save and push.
Save-Work -Note "Test push using email address for GitLab login"
