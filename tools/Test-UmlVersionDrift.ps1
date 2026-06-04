<#
.SYNOPSIS
    Detects drift between PlantUML diagram version pins and a module's
    manifest ModuleVersion. The mechanical anchor that converts a UML
    corpus from honor-system to verifiable.

.DESCRIPTION
    Reverse of theater: a .puml always renders, so a rendered diagram is
    not evidence it is current. This check compares the version token in
    each diagram's title (convention: a "(v1.2.3)" pin) against the
    repository's module manifest ModuleVersion and reports every diagram
    that is stale, unpinned, or untitled.

    Read-only. Never throws. Returns a structured result on every path.
    Fails OPEN: a repo with no UML directory (or an empty one) is
    reported as Not-Applicable (exit 0), not as a failure — the check
    must never block unrelated work.

    A repo with a UML corpus but NO manifest (a static site, a docs
    corpus) is NOT skipped: it runs in "presence mode" — every diagram
    must still carry SOME release identifier (a "(v1.2.3)" version, a
    "(Stage 0)" / "(Phase 2.1)" token, or a "(@d090b30)" short git SHA),
    even though there is no ModuleVersion to compare against. This is the
    smallest change that brings no-manifest projects inside the one
    enforced rule. Presence mode still exits 0 in advisory mode; only
    -FailOnDrift + an unpinned diagram exits 1.

    Per-repo by design: copy this one file into a repo (e.g. its Tools/
    directory) so the check travels with the repo if it is ever made
    public or handed off. One canonical template; many repo copies.

.PARAMETER RepoPath
    Repository root to scan. Required. No reliance on script location.

.PARAMETER FailOnDrift
    If set, exit code is 1 when any diagram is Drift or NoPin. Default
    behaviour still reports findings but exits 0 (advisory mode), so a
    project can adopt it before wiring it into a gate.

.EXAMPLE
    .\Test-UmlVersionDrift.ps1 -RepoPath C:\Sysadmin\Scripts\ClusterValidator

    Reports each diagram's pin vs the manifest version. A fully reconciled
    corpus prints all InSync and exits 0.

.EXAMPLE
    .\Test-UmlVersionDrift.ps1 -RepoPath C:\Repo -FailOnDrift

    Same scan, but exits 1 if any diagram is stale or unpinned — the form
    a CI step or pre-commit check uses to actually block drift.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $RepoPath,

    [switch] $FailOnDrift
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-DriftResult {
    <#
    .DESCRIPTION
    Internal. Builds a structured drift-check result object.
    Steps:
    1. Pack the status, repo path, manifest path, manifest version, diagram findings, and message into a pscustomobject.
    #>
    param($Status, $Manifest, $ManifestVersion, $Diagrams, $Message)
    [pscustomobject]@{
        Status          = $Status            # OK | Drift | NotApplicable | Error
        RepoPath        = $RepoPath
        Manifest        = $Manifest
        ManifestVersion = $ManifestVersion
        Diagrams        = $Diagrams           # array of per-file findings
        Message         = $Message
    }
}

try {
    if (-not (Test-Path -LiteralPath $RepoPath)) {
        $r = New-DriftResult 'NotApplicable' $null $null @() ('Repo path not found: {0}' -f $RepoPath)
        $r; exit 0
    }
    $repo = (Resolve-Path -LiteralPath $RepoPath).Path

    # --- Locate the module manifest (the project-root marker). ---
    # Candidate locations, no deep recursion (vendored manifests under
    # sub-trees are not the project's manifest): root-level *.psd1, then
    # the suite's standard nested layout repo\<leaf>\<leaf>.psd1. The
    # chosen manifest is the first candidate that PARSES and actually
    # carries a non-empty ModuleVersion — a config .psd1
    # (PSScriptAnalyzerSettings, build config) is correctly skipped.
    $repoLeaf  = Split-Path -Leaf $repo
    $cands     = New-Object System.Collections.Generic.List[string]
    foreach ($g in @(
            (Get-ChildItem -LiteralPath $repo -Filter *.psd1 -File -ErrorAction SilentlyContinue),
            (Get-ChildItem -LiteralPath (Join-Path $repo $repoLeaf) -Filter *.psd1 -File -ErrorAction SilentlyContinue)
        )) { foreach ($fi in @($g)) { if ($fi) { $cands.Add($fi.FullName) } } }

    # Prefer a manifest whose base name matches the repo folder.
    $ordered = $cands | Sort-Object @{ Expression = {
        [System.IO.Path]::GetFileNameWithoutExtension($_) -ne $repoLeaf } }

    $manifestPath = $null
    $manifestVersion = $null
    foreach ($cp in $ordered) {
        # Import-PowerShellDataFile parses data only — it does NOT execute
        # the manifest as code (no Invoke-Expression / dot-source). A
        # manifest is untrusted-shaped input from this check's view.
        try { $data = Import-PowerShellDataFile -LiteralPath $cp -ErrorAction Stop }
        catch { continue }
        if ($data -is [hashtable] -and $data.ContainsKey('ModuleVersion')) {
            $v = [string]$data['ModuleVersion']
            if (-not [string]::IsNullOrWhiteSpace($v)) {
                $manifestPath = $cp; $manifestVersion = $v; break
            }
        }
    }

    # No manifest → do NOT bail. Fall back to "pinned at all" presence
    # mode: a no-manifest project (a static site, a docs corpus) is still
    # inside the one enforced rule — every diagram must carry SOME release
    # identifier, even though there is no ModuleVersion to compare it to.
    $presenceMode = -not $manifestPath

    # --- Locate the UML directory (convention + known aliases). ---
    $umlDir = $null
    foreach ($cand in @('Docs\UML', 'docs\UML', 'architecture')) {
        $p = Join-Path $repo $cand
        if (Test-Path -LiteralPath $p) { $umlDir = (Resolve-Path -LiteralPath $p).Path; break }
    }
    if (-not $umlDir) {
        $r = New-DriftResult 'NotApplicable' $manifestPath $manifestVersion @() 'No UML directory (Docs/UML, docs/UML, architecture) — N/A.'
        $r; exit 0
    }

    $puml = @(Get-ChildItem -LiteralPath $umlDir -Filter *.puml -File -Recurse -ErrorAction SilentlyContinue)
    if ($puml.Count -eq 0) {
        $r = New-DriftResult 'NotApplicable' $manifestPath $manifestVersion @() 'UML directory contains no .puml files — N/A.'
        $r; exit 0
    }

    # Manifest mode: a "(v1.2.3)" / "(v1.2.3.4)" pin compared against the
    # manifest ModuleVersion. Presence mode (no manifest): accept any
    # release identifier — a version, a "(Stage 0)" / "(Phase 2.1)"
    # token, or a "(@d090b30)" short git SHA — and only check it is
    # present (there is no manifest version to compare against).
    $pinRegex     = '\(v(\d+\.\d+\.\d+(?:\.\d+)?)\)'
    $releaseRegex = '\((v\d+\.\d+\.\d+(?:\.\d+)?|(?:Stage|Phase)\s+\S+|@?[0-9a-f]{7,40})\)'
    $rx           = if ($presenceMode) { $releaseRegex } else { $pinRegex }

    $findings = foreach ($f in $puml) {
        $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
        $rel  = $f.FullName.Substring($repo.Length).TrimStart('\','/')
        $m    = if ($text) { [regex]::Match($text, $rx) } else { $null }

        if (-not $m -or -not $m.Success) {
            $status = 'NoPin'; $pinned = $null
        }
        elseif ($presenceMode) {
            # No manifest to compare against — presence is the whole test.
            $pinned = $m.Groups[1].Value
            $status = 'Pinned'
        }
        else {
            $pinned = $m.Groups[1].Value
            $status = if ($pinned -eq $manifestVersion) { 'InSync' } else { 'Drift' }
        }
        [pscustomobject]@{
            Diagram         = $rel
            PinnedVersion   = $pinned
            ManifestVersion = $manifestVersion
            Status          = $status
        }
    }

    $bad = @($findings | Where-Object { $_.Status -in @('Drift','NoPin') })
    if ($bad.Count -eq 0) {
        $okMsg = if ($presenceMode) {
            'No manifest — version comparison N/A; all {0} diagram(s) carry a release-identifier pin (presence mode).' -f $findings.Count
        }
        else {
            'All {0} diagram(s) pinned to {1}.' -f $findings.Count, $manifestVersion
        }
        $r = New-DriftResult 'OK' $manifestPath $manifestVersion $findings $okMsg
        $r; exit 0
    }

    $msg = if ($presenceMode) {
        '{0} of {1} diagram(s) carry no release-identifier pin (presence mode; no manifest to compare against).' -f `
            $bad.Count, $findings.Count
    }
    else {
        '{0} of {1} diagram(s) out of sync with manifest {2}: {3} drift, {4} unpinned.' -f `
            $bad.Count, $findings.Count, $manifestVersion,
            @($bad | Where-Object Status -eq 'Drift').Count,
            @($bad | Where-Object Status -eq 'NoPin').Count
    }
    $r = New-DriftResult 'Drift' $manifestPath $manifestVersion $findings $msg
    $r
    if ($FailOnDrift) { exit 1 } else { exit 0 }
}
catch {
    # Fail open on unexpected error: report, do not block.
    $r = New-DriftResult 'Error' $null $null @() ('Unexpected error (failing open): {0}' -f $_.Exception.Message)
    $r; exit 0
}
