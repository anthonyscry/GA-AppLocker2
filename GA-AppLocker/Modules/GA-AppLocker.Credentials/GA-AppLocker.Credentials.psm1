#region ===== MODULE HEADER =====
<#
.MODULE
    GA-AppLocker.Credentials

.DESCRIPTION
    Tiered credential management for GA-AppLocker Dashboard.
    Supports secure storage of credentials for different machine tiers:
    - Tier 0: Domain Controllers
    - Tier 1: Member Servers
    - Tier 2: Workstations

    Uses DPAPI for secure credential storage (user-scoped encryption).

.DEPENDENCIES
    - GA-AppLocker.Core (logging, config)

.CHANGELOG
    2026-01-17  v1.0.0  Initial release - Phase 3

.NOTES
    Credentials are encrypted using Windows DPAPI.
    Only the user who created the credential can decrypt it.
    Air-gapped environment compatible - no external dependencies.
#>
#endregion

#region ===== MODULE CONFIGURATION =====
$script:CredentialTiers = @{
    0 = 'DomainController'
    1 = 'Server'
    2 = 'Workstation'
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
    'New-CredentialProfile',
    'Get-CredentialProfile',
    'Get-AllCredentialProfiles',
    'Remove-CredentialProfile',
    'Test-CredentialProfile',
    'Get-CredentialForTier',
    'Get-CredentialStoragePath'
)
#endregion
