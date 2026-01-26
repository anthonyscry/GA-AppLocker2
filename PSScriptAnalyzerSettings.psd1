# PSScriptAnalyzer Settings for GA-AppLocker
# Run with: Invoke-ScriptAnalyzer -Path . -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse

@{
    # Severity levels to include (Error only - warnings excluded for WPF app)
    Severity = @('Error')

    # Rules to exclude
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidGlobalVars',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidAssignmentToAutomaticVariable',
        'PSReviewUnusedParameter',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingEmptyCatchBlock',
        'PSUseSingularNouns',
        'PSUseApprovedVerbs',
        'PSShouldProcess'
    )

    IncludeRules = @()

    Rules = @{
        PSAvoidUsingCmdletAliases = @{ Enable = $true }
        PSMisleadingBacktick = @{ Enable = $true }
        PSAvoidUsingPlainTextForPassword = @{ Enable = $true }
        PSAvoidUsingConvertToSecureStringWithPlainText = @{ Enable = $true }
    }
}
