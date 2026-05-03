function Complete-GELogSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('SUCCESS','FAILURE')]
        [string]$Outcome,

        [string]$UserMessage = '',

        [string]$ErrorMessage = ''
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $tail = New-Object System.Collections.Generic.List[string]
    $tail.Add('')
    $tail.Add(('=' * 60))
    $tail.Add("Outcome: $Outcome")
    $tail.Add("Finished UTC: $((Get-Date).ToUniversalTime().ToString('o'))")

    if (-not [string]::IsNullOrWhiteSpace($UserMessage)) {
        $tail.Add('')
        $tail.Add('User-facing message:')
        $tail.Add('  ' + $UserMessage)
    }

    if (-not [string]::IsNullOrWhiteSpace($ErrorMessage)) {
        $tail.Add('')
        $tail.Add('Inner error:')
        foreach ($subLine in ($ErrorMessage -split "`r?`n")) {
            $tail.Add('  ' + $subLine)
        }
    }

    $sb = New-Object System.Text.StringBuilder
    foreach ($l in $tail) {
        [void]$sb.AppendLine($l)
    }

    [System.IO.File]::AppendAllText(
        $Path,
        $sb.ToString(),
        [System.Text.UTF8Encoding]::new($false)
    )
}
