@{
    Severity = @('Error', 'Warning')

    IncludeDefaultRules = $true

    Rules = @{
        PSAvoidUsingPlainTextForPassword               = @{ Enable = $true }
        PSUsePSCredentialType                          = @{ Enable = $true }
        PSShouldProcess                                = @{ Enable = $true }
        PSAvoidUsingConvertToSecureStringWithPlainText = @{ Enable = $true }
        PSUseShouldProcessForStateChangingFunctions    = @{ Enable = $true }
    }
}
