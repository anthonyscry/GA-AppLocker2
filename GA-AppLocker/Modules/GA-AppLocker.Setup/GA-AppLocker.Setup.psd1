#
# Module manifest for module 'GA-AppLocker.Setup'
# Generated: 2026-01-31
#
# Environment initialization module for AppLocker deployment.
# Creates WinRM GPO, AppLocker GPOs, AD structure, and security groups.
#

@{
    RootModule        = 'GA-AppLocker.Setup.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'GA-AppLocker Team'
    CompanyName       = 'GA-AppLocker'
    Copyright         = '(c) 2026 GA-AppLocker. All rights reserved.'
    Description       = 'AppLocker environment initialization for GA-AppLocker Dashboard'
    PowerShellVersion = '5.1'
    RequiredModules   = @()
    FunctionsToExport = @(
        'Initialize-WinRMGPO',
        'Initialize-AppLockerGPOs',
        'Initialize-ADStructure',
        'Initialize-AppLockerEnvironment',
        'Get-SetupStatus',
        'Enable-WinRMGPO',
        'Disable-WinRMGPO',
        'Remove-WinRMGPO',
        'Initialize-DisableWinRMGPO',
        'Remove-DisableWinRMGPO'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('AppLocker', 'Setup', 'WinRM', 'GPO')
            ProjectUri = ''
        }
    }
}
