# PSScriptAnalyzer Settings for GA-AppLocker
# Run with: Invoke-ScriptAnalyzer -Path . -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse

@{
    # Severity levels to include
    Severity = @('Error', 'Warning')

    # Rules to exclude
    ExcludeRules = @(
        # Exclude Write-Host warnings for UI/console output
        'PSAvoidUsingWriteHost',
        # Allow positional parameters for common cmdlets
        'PSAvoidUsingPositionalParameters'
    )

    # Rules to include (if empty, all rules minus ExcludeRules are included)
    IncludeRules = @()

    # Rule-specific settings
    Rules = @{
        # Require approved verbs
        PSUseApprovedVerbs = @{
            Enable = $true
        }

        # Avoid using aliases
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }

        # Require explicit parameter names
        PSAvoidUsingPositionalParameters = @{
            Enable = $false
            CommandAllowList = @('Write-Host', 'Write-Output', 'Write-Verbose')
        }

        # Misleading backticks
        PSMisleadingBacktick = @{
            Enable = $true
        }

        # Avoid using plain text passwords
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }

        # Avoid using ConvertTo-SecureString with plain text
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }

        # Variable naming convention (PascalCase)
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true
            Placement = 'begin'
        }
    }
}
