@{
    RootModule        = 'GA-AppLocker.Policy.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'f6a7b8c9-d0e1-2345-6789-abcdef012345'
    Author            = 'GA-AppLocker Team'
    CompanyName       = 'GA-AppLocker'
    Copyright         = '(c) 2026 GA-AppLocker. All rights reserved.'
    Description       = 'AppLocker policy management for GA-AppLocker Dashboard'
    PowerShellVersion = '5.1'
    RequiredModules   = @()
    FunctionsToExport = @(
        'New-Policy',
        'Get-Policy',
        'Get-AllPolicies',
        'Remove-Policy',
        'Set-PolicyStatus',
        'Add-RuleToPolicy',
        'Remove-RuleFromPolicy',
        'Set-PolicyTarget',
        'Export-PolicyToXml',
        'Test-PolicyCompliance'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('AppLocker', 'Policy', 'Security', 'GPO')
            ProjectUri = ''
        }
    }
}
