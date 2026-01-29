#Requires -Version 5.1
#region ===== MODULE HEADER =====
<#
.MODULE
    GA-AppLocker.Validation

.DESCRIPTION
    Comprehensive validation suite to ensure generated AppLocker policies
    are accepted by Windows AppLocker. Validates XML schema, GUIDs, SIDs,
    rule conditions, and performs live import testing.

    Critical: Policies that fail these validations WILL be rejected by AppLocker.

.DEPENDENCIES
    - GA-AppLocker.Core (logging)

.CHANGELOG
    2026-01-28  v1.0.0  Initial release - policy validation pipeline

.NOTES
    Air-gapped environment compatible.
    No external dependencies.
#>
#endregion

#region ===== SAFE LOGGING WRAPPER =====
function script:Write-ValidationLog {
    param([string]$Message, [string]$Level = 'Info')
    if (Get-Command -Name 'Write-AppLockerLog' -ErrorAction SilentlyContinue) {
        Write-AppLockerLog -Message "[Validation] $Message" -Level $Level -NoConsole
    }
}
#endregion

#region ===== FUNCTION LOADING =====
$functionPath = Join-Path $PSScriptRoot 'Functions'

if (Test-Path $functionPath) {
    $functionFiles = Get-ChildItem -Path $functionPath -Filter '*.ps1' -ErrorAction SilentlyContinue

    foreach ($file in $functionFiles) {
        try {
            . $file.FullName
        }
        catch {
            Write-Warning "Failed to load function file: $($file.Name). Error: $($_.Exception.Message)"
        }
    }
}
#endregion

#region ===== EXPORTS =====
Export-ModuleMember -Function @(
    'Test-AppLockerXmlSchema',
    'Test-AppLockerRuleGuids',
    'Test-AppLockerRuleSids',
    'Test-AppLockerRuleConditions',
    'Test-AppLockerPolicyImport',
    'Invoke-AppLockerPolicyValidation'
)
#endregion
