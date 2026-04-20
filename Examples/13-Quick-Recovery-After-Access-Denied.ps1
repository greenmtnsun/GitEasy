# GitEasy example
# Scenario:
# You just saw:
#   HTTP Basic: Access denied
#
# This is the fastest recovery flow to try first.

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

# Step 1: Check the current remote.
Show-Remote

# Step 2: Clear saved login and test again.
Reset-Login
Test-Login

# Step 3:
# If the test still fails, switch cleanly to the HTTPS token flow below.
# Remove the # from these lines after you replace the address.
#
# Set-Token -WebAddress "https://gitlab.company.local/team/GitEasy.git"
# Test-Login

# Step 4:
# After the login test works, push your changes.
# Remove the # when ready.
#
# Save-Work -Note "Recovered after GitLab access denied"
