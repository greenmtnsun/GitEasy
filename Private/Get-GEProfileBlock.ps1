function Get-GEProfileBlock {
    <#
    .SYNOPSIS
    Return the marked block of startup lines GitEasy adds to a PowerShell profile.

    .DESCRIPTION
    Single source of truth for the auto-load block that Enable-GitEasy writes and Disable-GitEasy removes. Returns the begin marker, the end marker, and the full block (markers plus the load line) as a string array, so the two commands can never disagree on what to add or what to look for.

    .EXAMPLE
    $block = Get-GEProfileBlock
    $block.Lines   # the lines to add
    $block.Begin   # the line that marks the start of the block

    .NOTES
    Internal. No I/O.

    Steps:
    1. Define the begin and end marker lines.
    2. Build the full block: begin marker, friendly comments, the conditional load line, end marker.
    3. Return the markers and the block lines as a single object.

    .LINK
    Enable-GitEasy

    .LINK
    Disable-GitEasy
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $begin = '# >>> GitEasy (managed by Enable-GitEasy) >>>'
    $end   = '# <<< GitEasy (managed by Enable-GitEasy) <<<'

    $lines = @(
        $begin,
        '# Loads the plain-English Git commands at the start of every session.',
        '# Turn this off any time with: Disable-GitEasy',
        'if (Get-Module -ListAvailable -Name GitEasy) { Import-Module GitEasy }',
        $end
    )

    return [PSCustomObject]@{
        Begin = $begin
        End   = $end
        Lines = $lines
    }
}
