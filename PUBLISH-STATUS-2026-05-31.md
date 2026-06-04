# Publish status — GitEasy — 2026-05-31

**Audit:** cross-suite meta Claude, read-only (no publish performed). **For:** the GitEasy session preparing today's PSGallery publish.

## VERDICT: 🔴 BLOCKED — 2 hard items (1 gap just fixed)

1. **Version not bumped (HARD BLOCKER).** Local ModuleVersion **1.5.4** == PSGallery published **1.5.4**. PSGallery rejects a same-version publish. Bump to **1.5.5+** with matching ReleaseNotes + CHANGELOG before publishing.
2. **Publish script has uncommitted changes.** `GitEasy-internal\tools\Publish-GitEasy.ps1` is MODIFIED + uncommitted (lingering from the 2026-05-31 morning safety sweep). Review the diff and commit before running it — do not publish through an unreviewed publish script.
3. **PSSA-in-CI — now wired (2026-05-31).** `.github/workflows/pester.yml` had a `PSScriptAnalyzerSettings.psd1` but never ran it. A `PSScriptAnalyzer gate` step was added to BOTH jobs (PS5.1 + PS7), gating on Error severity. No longer a gap. *(First CI run confirms it's clean; if it surprises, narrow the `-Path`.)*

## Already passing
Test-ModuleManifest ✅ · Tags/ProjectUri/LicenseUri/ReleaseNotes ✅ · LICENSE ✅ · 66 source files parse clean ✅ · working tree clean ✅

## Definition of done before `Publish-Module`
- [ ] ModuleVersion bumped > 1.5.4 + ReleaseNotes/CHANGELOG updated
- [ ] Publish-GitEasy.ps1 diff reviewed + committed
- [ ] CI green (including the new PSSA gate)
- [ ] Publish via `GitEasy-internal\tools\Publish-GitEasy.ps1`

*Verify current versions with `Find-Module GitEasy`.*
