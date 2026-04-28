# Known Bugs and Fixes

## Fixed

- False conflict detection from LF/CRLF warnings.
- Save-Work missing NoPush support.
- Native git stderr caused false PowerShell failures.
- Commit message UTF-8 BOM pollution.

## Open

- Save-Work should push when the repo is clean but ahead of upstream.
- Move embedded Git runner logic into a private GE-prefixed helper.
- Add Pester coverage for the GitEasy bugs discovered during DBCCPROJECT publishing.
