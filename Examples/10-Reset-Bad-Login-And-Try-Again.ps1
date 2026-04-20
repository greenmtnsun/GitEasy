# GitEasy example
# Scenario:
# Git used to work, but now push fails because Windows likely saved a bad or old login.
#
# Use this when:
# - You changed passwords
# - You changed tokens
# - You switched accounts
# - Git keeps using the wrong login

Set-Location "C:\Path\To\Your\Repo"
Import-Module .\GitEasy.psm1 -Force

# Show the current remote first.
Show-Remote

# Clear the saved login for the current Git host.
Reset-Login

# Safe test. Git should prompt again if the old login was the problem.
Test-Login

# If the test works, go ahead and push.
Save-Work -Note "Retry after clearing saved Git login"
