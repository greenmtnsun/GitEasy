# GitEasy example
# Scenario:
# Your company uses SSH instead of HTTPS for GitLab.
#
# Requirements:
# - You already have an SSH key on your workstation
# - Your public key is already added to GitLab
#
# Notes:
# - SSH usually does NOT prompt for username/password like HTTPS does.
# - If Test-Login fails here, your SSH key setup likely needs work.

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

# Show the current remote.
Show-Remote

# Switch the repo to the SSH address from GitLab.
Set-Ssh -SshAddress "git@gitlab.company.local:team/GitEasy.git"

# Safely test whether the SSH setup works.
Test-Login

# Push your changes after the test passes.
Save-Work -Note "Test push with GitLab SSH"
