# PSScriptAnalyzer Settings for GA-AppLocker
# Run with: Invoke-ScriptAnalyzer -Path . -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse

@{
    # Severity levels to include
    Severity = @('Error', 'Warning')

    # Rules to exclude (justified for WPF app context)
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'                          # WPF app uses Write-Host for console diagnostics
        'PSAvoidUsingPositionalParameters'               # Common in PowerShell idioms
        'PSAvoidGlobalVars'                              # Required for WPF timer/dispatcher callbacks
        'PSUseShouldProcessForStateChangingFunctions'    # Overly strict for internal module functions
        'PSAvoidAssignmentToAutomaticVariable'           # False positives with $_ in closures
        'PSReviewUnusedParameter'                        # False positives in WPF event handlers
        'PSUseDeclaredVarsMoreThanAssignments'           # False positives with script-scope vars
        'PSAvoidUsingEmptyCatchBlock'                    # Intentional in try-catch-fallback patterns
        'PSUseSingularNouns'                             # Some plural nouns are natural (Get-AllRules)
        'PSUseApprovedVerbs'                             # Storage module uses Invoke-/Find- patterns
        'PSShouldProcess'                                # Internal functions don't need -WhatIf
    )

    Rules = @{
        PSAvoidUsingCmdletAliases                          = @{ Enable = $true }
        PSMisleadingBacktick                               = @{ Enable = $true }
        PSAvoidUsingPlainTextForPassword                   = @{ Enable = $true }
        PSAvoidUsingConvertToSecureStringWithPlainText      = @{ Enable = $true }
    }
}
