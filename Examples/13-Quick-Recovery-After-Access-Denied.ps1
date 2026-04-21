# GitEasy example
# Scenario:
# You just saw:
#   HTTP Basic: Access denied
#
# This is the fastest recovery flow to try first.

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

Show-Remote
Reset-Login
Test-Login

# If the test still fails, switch cleanly to the HTTPS token flow below.
# Remove the # from these lines after you replace the address.
#
# Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"
# Test-Login
#
# Save-Work -Note "Recovered after GitLab access denied"
