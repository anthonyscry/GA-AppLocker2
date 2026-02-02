#
# Module manifest for module 'GA-AppLocker.Deployment'
# Generated: 2026-01-17
#
# Deployment module for applying AppLocker policies to GPOs.
# Supports async deployment with progress tracking.
#

@{
    RootModule        = 'GA-AppLocker.Deployment.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b2c3d4e5-f6a7-8901-bcde-f12345678901'
    Author            = 'GA-AppLocker Team'
    CompanyName       = 'GA-AppLocker'
    Copyright         = '(c) 2026 GA-AppLocker. All rights reserved.'
    Description       = 'AppLocker policy deployment for GA-AppLocker Dashboard'
    PowerShellVersion = '5.1'
    RequiredModules   = @()
    FunctionsToExport = @(
        'New-DeploymentJob',
        'Get-DeploymentJob',
        'Get-AllDeploymentJobs',
        'Update-DeploymentJob',
        'Remove-DeploymentJob',
        'Start-Deployment',
        'Stop-Deployment',
        'Get-DeploymentStatus',
        'Test-GPOExists',
        'New-AppLockerGPO',
        'Import-PolicyToGPO',
        'Get-DeploymentHistory'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('AppLocker', 'Deployment', 'GPO', 'Security')
            ProjectUri = ''
        }
    }
}
