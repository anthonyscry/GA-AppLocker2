#Requires -Version 5.1
<#
.SYNOPSIS
    GA-AppLocker Policy Management Module

.DESCRIPTION
    Provides policy creation, management, and targeting functions
    for the GA-AppLocker Dashboard.

.NOTES
    Policies combine rules into deployable units that can be
    targeted to specific OUs or GPOs.
#>

# Get module path for loading functions
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$FunctionsPath = Join-Path $ModulePath 'Functions'

# Dot-source all function files
if (Test-Path $FunctionsPath) {
    Get-ChildItem -Path $FunctionsPath -Filter '*.ps1' -File | ForEach-Object {
        . $_.FullName
    }
}

# Export all public functions
Export-ModuleMember -Function @(
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
