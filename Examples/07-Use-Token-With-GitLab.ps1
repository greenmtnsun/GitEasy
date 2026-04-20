# GitEasy example
# Scenario:
# Your GitLab remote uses HTTPS and your company expects a Personal Access Token.
#
# What to type when Git prompts:
#   Username: your GitLab username (or work email if your company uses that)
#   Password: your GitLab token
#
# Notes:
# - This sets the remote to the HTTPS address you give it.
# - It also clears old saved login so Git can ask again.
# - Test-Login is safe. It checks access without pushing code.

# Move into your repo first.
Set-Location "C:\Path\To\Your\Repo"

# Load GitEasy if needed.
Import-Module .\GitEasy.psm1 -Force

# Optional: See where Git points now.
Show-Remote

# Set the HTTPS remote and clear old saved login.
Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"

# Safely test whether Git can reach GitLab.
Test-Login

# If Test-Login works, save and push your change.
Save-Work -Note "Test push with GitLab token"
