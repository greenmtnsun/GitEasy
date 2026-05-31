@{
    Severity = @('Error', 'Warning')

    IncludeDefaultRules = $true

    Rules = @{
        PSAvoidUsingPlainTextForPassword               = @{ Enable = $true }
        PSUsePSCredentialType                          = @{ Enable = $true }
        PSShouldProcess                                = @{ Enable = $true }
        PSAvoidUsingConvertToSecureStringWithPlainText = @{ Enable = $true }
        PSUseShouldProcessForStateChangingFunctions    = @{ Enable = $true }
        # Write-Host is project convention (structured output to host, not pipeline)
        PSAvoidUsingWriteHost                          = @{ Enable = $false }
    }
}
