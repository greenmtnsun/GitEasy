function Format-GESafeLogLine {
    <#
    .SYNOPSIS
    Redact credential-bearing lines before they are written to a diagnostic log.

    .DESCRIPTION
    The git credential protocol (and the helpers Reset-Login drives — git credential reject, git credential-manager erase) can echo lines of the form password=..., secret=..., token=..., bearer=..., or Authorization: ... on their stdout/stderr. Reset-Login captures that output and passes it to Add-GELogStep, which writes it verbatim to a plaintext file on disk. Any such line must have its value replaced before it lands in the log.

    Format-GESafeLogLine takes the captured output lines and returns them with the value of any sensitive key replaced by [redacted]. The key itself is kept so the log still shows that a credential field was present (useful for diagnostics) without persisting the secret.

    .PARAMETER Line
    The output lines to sanitise. Accepts pipeline input.

    .EXAMPLE
    @('protocol=https','password=ghp_REAL') | Format-GESafeLogLine
    # -> 'protocol=https', 'password=[redacted]'

    .NOTES
    Internal. Read/output-path sanitiser. Pairs with Add-GELogStep (the sink) and Format-GESafeUrl (the URL-shaped equivalent).

    .LINK
    Add-GELogStep

    .LINK
    Reset-Login

    .LINK
    Format-GESafeUrl
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Line = @()
    )

    begin {
        # key=value (git credential protocol) or "Header: value" (HTTP-style).
        # The optional "proxy-" prefix covers Proxy-Authorization headers,
        # which are credential-bearing the same way Authorization is.
        # The anchor at ^\s* is intentional: only line-shaped credential
        # output is redacted. A literal mid-sentence "password=foo" inside
        # narrative text is left alone, by design.
        $pattern = '(?i)^(?<lead>\s*)(?<key>password|secret|token|bearer|(?:proxy-)?authorization)(?<sep>\s*[:=]\s*).+$'
    }

    process {
        foreach ($l in $Line) {
            if ($null -eq $l) { continue }
            [System.Text.RegularExpressions.Regex]::Replace(
                $l, $pattern, '${lead}${key}${sep}[redacted]'
            )
        }
    }
}
