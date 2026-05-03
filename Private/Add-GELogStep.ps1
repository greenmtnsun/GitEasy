function Add-GELogStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Step,

        [int]$ExitCode = 0,

        [string[]]$Output = @(),

        [string]$Note = ''
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("[step] $Step")
    $lines.Add("[exit] $ExitCode")

    if (-not [string]::IsNullOrWhiteSpace($Note)) {
        $lines.Add("[note] $Note")
    }

    if ($Output -and $Output.Count -gt 0) {
        $lines.Add('[out]')
        foreach ($line in $Output) {
            if ($null -eq $line) { continue }
            $text = $line.ToString()
            foreach ($subLine in ($text -split "`r?`n")) {
                $lines.Add('  ' + $subLine)
            }
        }
    }

    $lines.Add('')

    $sb = New-Object System.Text.StringBuilder
    foreach ($l in $lines) {
        [void]$sb.AppendLine($l)
    }

    [System.IO.File]::AppendAllText(
        $Path,
        $sb.ToString(),
        [System.Text.UTF8Encoding]::new($false)
    )
}
