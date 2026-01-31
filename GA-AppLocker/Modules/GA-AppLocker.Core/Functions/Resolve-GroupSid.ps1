<#
.SYNOPSIS
    Resolves an AD group name to its SID, with graceful fallback.

.DESCRIPTION
    Attempts to resolve a group name to a Security Identifier (SID) using
    .NET NTAccount translation. If the machine is not domain-joined or the
    group doesn't exist, returns a placeholder SID pattern.

    This function is designed for air-gapped environments where AD modules
    may not be available. It uses pure .NET calls (no ActiveDirectory module).

.PARAMETER GroupName
    The name of the group to resolve (e.g., 'AppLocker-Users').

.PARAMETER FallbackToPlaceholder
    If $true (default), returns a wildcard SID pattern when resolution fails.
    If $false, returns $null on failure.

.EXAMPLE
    Resolve-GroupSid -GroupName 'AppLocker-Users'
    # Returns: S-1-5-21-1234567890-1234567890-1234567890-1234

.EXAMPLE
    Resolve-GroupSid -GroupName 'RESOLVE:AppLocker-Admins'
    # Strips RESOLVE: prefix and resolves 'AppLocker-Admins'

.OUTPUTS
    [string] The resolved SID, or a placeholder pattern on failure.
#>
function Resolve-GroupSid {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$GroupName,

        [Parameter()]
        [switch]$FallbackToPlaceholder = $true
    )

    # Strip RESOLVE: prefix if present
    if ($GroupName.StartsWith('RESOLVE:')) {
        $GroupName = $GroupName.Substring(8)
    }

    # Well-known SIDs - return immediately without lookup
    $wellKnown = @{
        'Everyone'            = 'S-1-1-0'
        'Administrators'      = 'S-1-5-32-544'
        'Users'               = 'S-1-5-32-545'
        'Authenticated Users' = 'S-1-5-11'
    }

    if ($wellKnown.ContainsKey($GroupName)) {
        return $wellKnown[$GroupName]
    }

    # Cache for resolved/failed groups (avoid repeated lookups and warning spam)
    if (-not $script:ResolvedGroupCache) {
        $script:ResolvedGroupCache = @{}
    }
    if ($script:ResolvedGroupCache.ContainsKey($GroupName)) {
        return $script:ResolvedGroupCache[$GroupName]
    }

    # Try .NET NTAccount translation (works for domain and local groups)
    try {
        $ntAccount = [System.Security.Principal.NTAccount]::new($GroupName)
        $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
        
        if ($sid) {
            try {
                Write-AppLockerLog -Message "Resolved group '$GroupName' to SID: $($sid.Value)" -Level 'INFO'
            } catch { }
            $script:ResolvedGroupCache[$GroupName] = $sid.Value
            return $sid.Value
        }
    }
    catch {
        # NTAccount translation failed - group may not exist or not domain-joined
    }

    # Try with domain prefix (DOMAIN\GroupName)
    try {
        $domain = $env:USERDOMAIN
        if ($domain -and $domain -ne $env:COMPUTERNAME) {
            $ntAccount = [System.Security.Principal.NTAccount]::new("$domain\$GroupName")
            $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
            
            if ($sid) {
                try {
                    Write-AppLockerLog -Message "Resolved group '$domain\$GroupName' to SID: $($sid.Value)" -Level 'INFO'
                } catch { }
                $script:ResolvedGroupCache[$GroupName] = $sid.Value
                return $sid.Value
            }
        }
    }
    catch {
        # Also failed with domain prefix
    }

    # Log warning only once per group name
    try {
        Write-AppLockerLog -Message "Could not resolve group '$GroupName' - using UNRESOLVED placeholder (group may not exist or machine not domain-joined)" -Level 'WARNING'
    } catch { }

    # Fallback: return placeholder or null
    if ($FallbackToPlaceholder) {
        $fallback = "UNRESOLVED:$GroupName"
        $script:ResolvedGroupCache[$GroupName] = $fallback
        return $fallback
    }

    $script:ResolvedGroupCache[$GroupName] = $null
    return $null
}
