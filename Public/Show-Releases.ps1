function Show-Releases {
    <#
    .SYNOPSIS
    Show the named releases recorded in the active project.

    .DESCRIPTION
    Show-Releases lists every release marker (annotated tag) in the active project, in newest-first order, with the version name, date, and note.

    .PARAMETER Pattern
    Optional wildcard pattern to filter releases (for example, `v1.*` for the v1 line only). Uses Git's tag-pattern syntax.

    .PARAMETER Count
    Maximum number of releases to return. Defaults to 100. Validated to the range 1-1000.

    .EXAMPLE
    Show-Releases

    .EXAMPLE
    Show-Releases -Pattern 'v1.*'

    .EXAMPLE
    Show-Releases -Count 5

    .NOTES
    Returns structured objects you can pipe and filter. Each object has Repository, Version, Date, and Note.

    .LINK
    New-Release

    .LINK
    Show-History
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns', '',
        Justification = 'GitEasy uses plain-English plural names as a brand choice; singular form is exported as an alias.'
    )]
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    [Alias('Show-Release')]
    param(
        [string]$Pattern = '',

        [ValidateRange(1, 1000)]
        [int]$Count = 100
    )

    $root = Get-GERepoRoot

    $gitArgs = @(
        'for-each-ref',
        '--format=%(refname:short)%09%(taggerdate:short)%09%(subject)',
        "--count=$Count",
        '--sort=-taggerdate'
    )

    if ([string]::IsNullOrWhiteSpace($Pattern)) {
        $gitArgs += 'refs/tags/'
    }
    else {
        $gitArgs += "refs/tags/$Pattern"
    }

    $r = Invoke-GEGit -ArgumentList $gitArgs -WorkingDirectory $root -AllowFailure

    if ($r.ExitCode -ne 0) {
        return @()
    }

    $results = New-Object System.Collections.Generic.List[object]

    foreach ($line in $r.Output) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $parts = @($line -split "`t", 3)

        $version = if ($parts.Count -ge 1) { $parts[0].Trim() } else { '' }
        $date    = if ($parts.Count -ge 2) { $parts[1].Trim() } else { '' }
        $note    = if ($parts.Count -ge 3) { $parts[2].Trim() } else { '' }

        if ([string]::IsNullOrWhiteSpace($version)) { continue }

        $results.Add([PSCustomObject]@{
            Repository = $root
            Version    = $version
            Date       = $date
            Note       = $note
        })
    }

    return $results.ToArray()
}
