function Get-GEEnvironmentInfo {
    <#
    .SYNOPSIS
    Collect a small, safe snapshot of the environment for a bug report.

    .DESCRIPTION
    Returns a structured object describing the operating system, the PowerShell version and edition, the installed GitEasy version, and the installed Git version. Contains no paths, user names, or credentials. Used by New-BugReport to pre-fill the report with the facts a maintainer needs first.

    .PARAMETER LogPath
    Optional diagnostic log path; passed through to the Git version probe.

    .EXAMPLE
    $info = Get-GEEnvironmentInfo

    .NOTES
    Internal. Reads version facts only; writes nothing.

    Steps:
    1. Read the operating system description in a way that works on both PowerShell editions.
    2. Read the PowerShell version and edition.
    3. Read the loaded GitEasy module version, if the module is loaded.
    4. Ask Git for its version, tolerating Git not being installed.
    5. Return the facts as a single structured object.

    .LINK
    New-BugReport
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$LogPath = ''
    )

    $osDescription = 'unknown'
    if ($PSVersionTable.ContainsKey('OS') -and -not [string]::IsNullOrWhiteSpace($PSVersionTable.OS)) {
        $osDescription = [string]$PSVersionTable.OS
    }
    else {
        try {
            $osDescription = [System.Environment]::OSVersion.VersionString
        }
        catch {
            $osDescription = 'unknown'
        }
    }

    $psVersion = [string]$PSVersionTable.PSVersion

    $psEdition = 'Desktop'
    if ($PSVersionTable.ContainsKey('PSEdition') -and -not [string]::IsNullOrWhiteSpace($PSVersionTable.PSEdition)) {
        $psEdition = [string]$PSVersionTable.PSEdition
    }

    $gitEasyVersion = 'unknown'
    $module = Get-Module GitEasy | Select-Object -First 1
    if ($module) {
        $gitEasyVersion = $module.Version.ToString()
    }

    $gitVersion = 'not found'
    try {
        $probe = Invoke-GEGit -ArgumentList @('--version') -LogPath $LogPath -AllowFailure
        if ($probe.ExitCode -eq 0) {
            $firstLine = @($probe.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) | Select-Object -First 1
            if ($firstLine) {
                $gitVersion = [string]$firstLine
            }
        }
    }
    catch {
        $gitVersion = 'not found'
    }

    return [PSCustomObject]@{
        OperatingSystem   = $osDescription
        PowerShellVersion = $psVersion
        PowerShellEdition = $psEdition
        GitEasyVersion    = $gitEasyVersion
        GitVersion        = $gitVersion
    }
}
