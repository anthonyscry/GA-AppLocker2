<#
.SYNOPSIS
    Retrieves Active Directory domain information.

.DESCRIPTION
    Auto-detects the current domain and returns domain details.
    Falls back to LDAP when ActiveDirectory module is not available.

.PARAMETER UseLdap
    Force using LDAP instead of AD module.

.PARAMETER Server
    LDAP server to connect to (for LDAP fallback).

.PARAMETER Port
    LDAP port (default: 389).

.EXAMPLE
    $domain = Get-DomainInfo
    Write-Host "Connected to: $($domain.Data.DnsRoot)"

.OUTPUTS
    [PSCustomObject] Result object with Success, Data, and Error properties.
#>
function Get-DomainInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [switch]$UseLdap,
        
        [Parameter()]
        [string]$Server,
        
        [Parameter()]
        [int]$Port = 389,
        
        [Parameter()]
        [pscredential]$Credential
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    # Check if we should use LDAP
    $useAdModule = -not $UseLdap -and (Get-Module -ListAvailable -Name ActiveDirectory)
    
    if ($useAdModule) {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop

            $domain = Get-ADDomain -ErrorAction Stop
            $forest = Get-ADForest -ErrorAction Stop

            $dcs = Get-ADDomainController -Filter * -ErrorAction SilentlyContinue |
                Select-Object -Property Name, HostName, IPv4Address, Site, IsGlobalCatalog

            $result.Data = [PSCustomObject]@{
                Name              = $domain.Name
                DnsRoot           = $domain.DNSRoot
                NetBIOSName       = $domain.NetBIOSName
                DistinguishedName = $domain.DistinguishedName
                DomainControllers = $dcs
                Forest            = $forest.Name
                ForestMode        = $forest.ForestMode
                DomainMode        = $domain.DomainMode
                PDCEmulator       = $domain.PDCEmulator
                InfrastructureMaster = $domain.InfrastructureMaster
                Source            = 'ActiveDirectory'
            }

            $result.Success = $true
            Write-AppLockerLog -Message "Domain detected: $($domain.DNSRoot)" -NoConsole
            return $result
        }
        catch {
            Write-AppLockerLog -Level Warning -Message "AD module failed, falling back to LDAP: $($_.Exception.Message)"
        }
    }
    
    # LDAP fallback
    Write-AppLockerLog -Message "Using LDAP fallback for domain info" -NoConsole
    $ldapResult = Get-DomainInfoViaLdap -Server $Server -Port $Port -Credential $Credential
    
    if ($ldapResult.Success) {
        $ldapResult.Data | Add-Member -NotePropertyName 'Source' -NotePropertyValue 'LDAP' -Force
    }
    
    return $ldapResult
}
