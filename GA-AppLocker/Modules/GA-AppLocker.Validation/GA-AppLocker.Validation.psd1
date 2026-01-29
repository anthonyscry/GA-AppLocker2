#
# Module manifest for module 'GA-AppLocker.Validation'
# Generated: 2026-01-28
#
# Policy validation module ensuring generated AppLocker policies
# are accepted by Windows AppLocker before deployment.
#

@{
    RootModule        = 'GA-AppLocker.Validation.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b7c8d9e0-f1a2-3456-7890-bcdef1234567'
    Author            = 'GA-AppLocker Team'
    CompanyName       = 'GA-AppLocker'
    Copyright         = '(c) 2026 GA-AppLocker. All rights reserved.'
    Description       = 'AppLocker policy XML validation for GA-AppLocker Dashboard. Validates schema, GUIDs, SIDs, rule conditions, and live import readiness.'
    PowerShellVersion = '5.1'
    CLRVersion        = '4.0'
    DotNetFrameworkVersion = '4.7.2'
    RequiredModules   = @()
    FunctionsToExport = @(
        'Test-AppLockerXmlSchema',
        'Test-AppLockerRuleGuids',
        'Test-AppLockerRuleSids',
        'Test-AppLockerRuleConditions',
        'Test-AppLockerPolicyImport',
        'Invoke-AppLockerPolicyValidation'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('AppLocker', 'Validation', 'Security', 'Policy', 'XML')
            ProjectUri = ''
            ReleaseNotes = @'
Version 1.0.0:
- Initial release
- Test-AppLockerXmlSchema: Validates XML structure, collection types, enforcement modes
- Test-AppLockerRuleGuids: GUID format (uppercase), uniqueness checks
- Test-AppLockerRuleSids: SID format validation, well-known SID resolution
- Test-AppLockerRuleConditions: Publisher, Hash, Path condition validation
- Test-AppLockerPolicyImport: Live import test via Test-AppLockerPolicy cmdlet
- Invoke-AppLockerPolicyValidation: Full 5-stage validation pipeline with reporting
'@
        }
    }
}
