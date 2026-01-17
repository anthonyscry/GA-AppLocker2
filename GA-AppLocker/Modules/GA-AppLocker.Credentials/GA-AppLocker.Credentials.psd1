@{
    RootModule        = 'GA-AppLocker.Credentials.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'c3d4e5f6-a7b8-9012-cdef-345678901234'
    Author            = 'GA-AppLocker Team'
    CompanyName       = 'GA-AppLocker'
    Copyright         = '(c) 2026 GA-AppLocker. All rights reserved.'
    Description       = 'Tiered credential management for GA-AppLocker Dashboard'
    PowerShellVersion = '5.1'
    RequiredModules   = @(
        @{ ModuleName = 'GA-AppLocker.Core'; ModuleVersion = '1.0.0' }
    )
    FunctionsToExport = @(
        'New-CredentialProfile',
        'Get-CredentialProfile',
        'Get-AllCredentialProfiles',
        'Remove-CredentialProfile',
        'Test-CredentialProfile',
        'Get-CredentialForTier',
        'Get-CredentialStoragePath'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('AppLocker', 'Credentials', 'Security', 'DPAPI')
            ProjectUri = ''
        }
    }
}
