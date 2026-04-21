# GitEasy example
# Scenario:
# Your company uses SSH instead of HTTPS for GitLab.
#
# Requirements:
# - You already have an SSH key on your workstation
# - Your public key is already added to GitLab

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

Show-Remote
Set-Ssh -SshAddress "git@gitlab.company.local:team/GitEasy.git"
Test-Login
Save-Work -Note "Test push with GitLab SSH"
