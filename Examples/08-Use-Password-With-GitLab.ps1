# GitEasy example
# Scenario:
# Your GitLab remote uses HTTPS and your company still allows normal login/password.
#
# What to type when Git prompts:
#   Username: your GitLab username, work login, or work email
#   Password: your normal GitLab password
#
# Notes:
# - Many companies do NOT allow this anymore.
# - If you get "HTTP Basic: Access denied", switch to the token example instead.

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

# Show the current remote so you know what Git is using.
Show-Remote

# Use the HTTPS remote.
Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"

# Clear old saved login just in case Windows cached the wrong one.
Reset-Login

# Safely test the login before trying a push.
Test-Login

# Push only after the login test works.
Save-Work -Note "Test push with GitLab password"
