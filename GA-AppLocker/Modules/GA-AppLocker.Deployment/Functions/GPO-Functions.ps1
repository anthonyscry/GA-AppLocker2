function Test-GPOExists {
    <#
    .SYNOPSIS
        Tests if a GPO exists.


.DESCRIPTION
    Tests if a GPO exists. Returns a result object indicating success or failure. Check the Success property of the returned hashtable.

    .PARAMETER GPOName
        The name of the GPO to check.

    .EXAMPLE
        Test-GPOExists -GPOName "AppLocker-Workstations"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GPOName
    )

    try {
        # Check if GroupPolicy module is available
        if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
            return @{
                Success        = $false
                Data           = $null
                Error          = 'GroupPolicy module not available. Install RSAT-GPMC feature.'
                ManualRequired = $true
            }
        }

        Import-Module GroupPolicy -ErrorAction Stop

        $gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue

        return @{
            Success = $true
            Data    = ($null -ne $gpo)
            Message = if ($gpo) { "GPO '$GPOName' exists" } else { "GPO '$GPOName' does not exist" }
        }
    }
    catch {
        return @{
            Success = $false
            Data    = $null
            Error   = "Could not verify GPO: $($_.Exception.Message)"
        }
    }
}

function Test-GPOWritePermission {
    <#
    .SYNOPSIS
        Tests if current user has permission to create/modify GPOs.

    .DESCRIPTION
        Checks if current user is a Domain Administrator or has GPO creation permissions.
        Uses WindowsPrincipal to check group memberships.

    .EXAMPLE
        Test-GPOWritePermission
        # Returns: @{ Success = $true }
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction Stop
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)

        # Check if user is Domain Admin (SID: S-1-5-32-544)
        $domainAdminSid = 'S-1-5-32-544'
        $isDomainAdmin = $principal.IsInRole($domainAdminSid)

        # Check if user is Enterprise Admin (SID: S-1-5-32-519)
        $enterpriseAdminSid = 'S-1-5-32-519'
        $isEnterpriseAdmin = $principal.IsInRole($enterpriseAdminSid)

        # Check if user is in Group Policy Creator Owners (SID: S-1-5-32-580)
        $gpoCreatorSid = 'S-1-5-32-580'
        $isGPOCreator = $principal.IsInRole($gpoCreatorSid)

        if ($isDomainAdmin -or $isEnterpriseAdmin -or $isGPOCreator) {
            $roleInfo = if ($isDomainAdmin) { 'Domain Admin' }
                       elseif ($isEnterpriseAdmin) { 'Enterprise Admin' }
                       elseif ($isGPOCreator) { 'GPO Creator Owner' }
                       else { 'Unknown' }

            Write-AppLockerLog -Message "User has GPO write permission (Member of: $roleInfo)" -Level 'DEBUG'
            return @{
                Success = $true
                Data    = @{
                    IsDomainAdmin     = $isDomainAdmin
                    IsEnterpriseAdmin = $isEnterpriseAdmin
                    IsGPOCreator      = $isGPOCreator
                    Role              = $roleInfo
                }
            }
        } else {
            Write-AppLockerLog -Message 'User does not have GPO write permission' -Level 'WARNING'
            return @{
                Success = $false
                Error   = 'Insufficient permissions to create/modify GPOs. Must be Domain Admin, Enterprise Admin, or member of Group Policy Creator Owners.'
            }
        }
    }
    catch {
        Write-AppLockerLog -Level Error -Message "GPO permission check failed: $($_.Exception.Message)"
        return @{
            Success = $false
            Error   = "Could not verify GPO permissions: $($_.Exception.Message)"
        }
    }
}

function New-AppLockerGPO {
    <#
    .SYNOPSIS
        Creates a new GPO for AppLocker policies.


.DESCRIPTION
    Creates a new GPO for AppLocker policies.

    .PARAMETER GPOName
        The name for the new GPO.

    .PARAMETER Comment
        Optional comment/description for the GPO.

    .EXAMPLE
        New-AppLockerGPO -GPOName "AppLocker-Workstations"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GPOName,

        [Parameter(Mandatory = $false)]
        [string]$Comment = 'Created by GA-AppLocker Dashboard'
    )

    try {
        $permCheck = Test-GPOWritePermission
        if (-not $permCheck.Success) {
            return @{
                Success = $false
                Error   = $permCheck.Error
            }
        }

        # Check if GroupPolicy module is available
        if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
            return @{
                Success = $false
                Error   = 'GroupPolicy module not available. Install RSAT-GPMC feature.'
            }
        }

        Import-Module GroupPolicy -ErrorAction Stop

        # Check if GPO already exists
        $existing = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
        if ($existing) {
            return @{
                Success = $true
                Data    = $existing
                Message = "GPO '$GPOName' already exists"
            }
        }

        # Create new GPO
        $gpo = New-GPO -Name $GPOName -Comment $Comment -ErrorAction Stop

        Write-AppLockerLog -Message "Created GPO: $GPOName"

        return @{
            Success = $true
            Data    = $gpo
            Message = "GPO '$GPOName' created successfully"
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

function Import-PolicyToGPO {
    <#
    .SYNOPSIS
        Imports an AppLocker policy XML to a GPO.

    .DESCRIPTION
        Uses Set-AppLockerPolicy to import the XML policy
        to the specified GPO.

    .PARAMETER GPOName
        The name of the target GPO.

    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.

    .PARAMETER Merge
        If true, merge with existing policy. If false, replace.

    .EXAMPLE
        Import-PolicyToGPO -GPOName "AppLocker-Workstations" -XmlPath "C:\policy.xml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GPOName,

        [Parameter(Mandatory = $true)]
        [string]$XmlPath,

        [Parameter(Mandatory = $false)]
        [switch]$Merge
    )

    try {
        if (-not (Test-Path $XmlPath)) {
            return @{
                Success = $false
                Error   = "XML file not found: $XmlPath"
            }
        }

        $permCheck = Test-GPOWritePermission
        if (-not $permCheck.Success) {
            return @{
                Success = $false
                Error   = $permCheck.Error
            }
        }

        # Check if required modules are available
        if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
            return @{
                Success = $false
                Error   = 'GroupPolicy module not available. Install RSAT-GPMC feature.'
            }
        }

        Import-Module GroupPolicy -ErrorAction Stop

        # Get GPO
        $gpo = Get-GPO -Name $GPOName -ErrorAction Stop

        # Get domain DN for LDAP path
        $domain = $null
        try {
            $domain = Get-ADDomain -ErrorAction Stop
        } catch {
            Write-AppLockerLog -Level Warning -Message "Get-ADDomain failed: $($_.Exception.Message). Trying LDAP fallback."
        }

        if (-not $domain) {
            # Fallback: derive domain DN from environment
            try {
                $rootDSE = [ADSI]'LDAP://RootDSE'
                $domainDN = $rootDSE.defaultNamingContext.ToString()
            } catch {
                return @{
                    Success = $false
                    Error   = 'Unable to retrieve Active Directory domain information. Ensure the machine is domain-joined.'
                }
            }
        } else {
            $domainDN = $domain.DistinguishedName
        }
        $ldapPath = "LDAP://CN={$($gpo.Id)},CN=Policies,CN=System,$domainDN"
        Write-AppLockerLog -Message "Import-PolicyToGPO: LDAP path = $ldapPath"

        # Set AppLocker policy using PowerShell
        # Note: Set-AppLockerPolicy requires AppLocker module
        if (Get-Command -Name 'Set-AppLockerPolicy' -ErrorAction SilentlyContinue) {
            # -XmlPolicy expects a FILE PATH, not XML content
            # Export-PolicyToXml already writes BOM-free UTF-8 so the file is clean
            $resolvedPath = (Resolve-Path $XmlPath).Path
            Write-AppLockerLog -Message "Import-PolicyToGPO: Importing XML from $resolvedPath"

            if ($Merge) {
                Set-AppLockerPolicy -XmlPolicy $resolvedPath -Ldap $ldapPath -Merge
            }
            else {
                Set-AppLockerPolicy -XmlPolicy $resolvedPath -Ldap $ldapPath
            }
        }
        else {
            # Set-AppLockerPolicy not available - cannot auto-import
            Write-AppLockerLog -Level Warning -Message "Set-AppLockerPolicy not available. Policy exported to: $XmlPath"
            Write-AppLockerLog -Message "Manual import required: Use GPMC to import the policy XML"

            return @{
                Success        = $false
                Data           = @{
                    GPOName = $GPOName
                    XmlPath = $XmlPath
                }
                Error          = 'Set-AppLockerPolicy cmdlet not available. Manual import required via GPMC.'
                ManualRequired = $true
            }
        }

        Write-AppLockerLog -Message "Policy imported to GPO: $GPOName"

        return @{
            Success = $true
            Data    = @{
                GPOName = $GPOName
                GPOId   = $gpo.Id
            }
            Message = "Policy imported to GPO '$GPOName'"
        }
    }
    catch {
        Write-AppLockerLog -Level Error -Message "Import-PolicyToGPO failed: $($_.Exception.Message)"
        return @{
            Success = $false
            Data    = $null
            Error   = $_.Exception.Message
        }
    }
}

function Get-DeploymentHistory {
    <#
    .SYNOPSIS
        Gets deployment history entries.


.DESCRIPTION
    Gets deployment history entries.

    .PARAMETER JobId
        Optional filter by job ID.

    .PARAMETER Limit
        Maximum number of entries to return.

    .EXAMPLE
        Get-DeploymentHistory
        Get-DeploymentHistory -JobId "abc123"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$JobId,

        [Parameter(Mandatory = $false)]
        [int]$Limit = 100
    )

    try {
        $dataPath = Get-AppLockerDataPath
        $historyPath = Join-Path $dataPath 'DeploymentHistory'

        if (-not (Test-Path $historyPath)) {
            return @{
                Success = $true
                Data    = @()
            }
        }

        $historyFiles = Get-ChildItem -Path $historyPath -Filter '*.json' -File
        $entries = @()

        foreach ($file in $historyFiles) {
            $entry = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            if ([string]::IsNullOrEmpty($JobId) -or $entry.JobId -eq $JobId) {
                $entries += $entry
            }
        }

        # Sort by timestamp descending and limit
        $entries = $entries | Sort-Object -Property Timestamp -Descending | Select-Object -First $Limit

        return @{
            Success = $true
            Data    = $entries
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
