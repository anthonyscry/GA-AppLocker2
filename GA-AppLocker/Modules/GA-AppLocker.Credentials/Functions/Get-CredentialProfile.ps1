<#
.SYNOPSIS
    Retrieves credential profiles from storage.

.DESCRIPTION
    Gets one or more credential profiles by name, ID, or tier.
    Returns profile metadata (password remains encrypted).

.PARAMETER Name
    Name of the credential profile to retrieve.

.PARAMETER Id
    GUID of the credential profile to retrieve.

.PARAMETER Tier
    Get all profiles for a specific tier.

.EXAMPLE
    Get-CredentialProfile -Name 'DomainAdmin'

.EXAMPLE
    Get-CredentialProfile -Tier 0

.OUTPUTS
    [PSCustomObject] Result with Success, Data (profile(s)), and Error.

.NOTES
    Author: GA-AppLocker Team
    Version: 1.0.0
#>
function Get-CredentialProfile {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(ParameterSetName = 'ById')]
        [string]$Id,

        [Parameter(ParameterSetName = 'ByTier')]
        [ValidateSet(0, 1, 2)]
        [int]$Tier
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    try {
        $credPath = Get-CredentialStoragePath
        $profiles = @()

        $files = Get-ChildItem -Path $credPath -Filter '*.json' -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $profiles += $content
        }

        #region --- Filter Results ---
        $filtered = switch ($PSCmdlet.ParameterSetName) {
            'ByName' {
                if ($Name) {
                    $profiles | Where-Object { $_.Name -eq $Name }
                }
                else {
                    $profiles
                }
            }
            'ById' {
                $profiles | Where-Object { $_.Id -eq $Id }
            }
            'ByTier' {
                $profiles | Where-Object { $_.Tier -eq $Tier }
            }
        }
        #endregion

        $result.Success = $true
        $result.Data = $filtered
    }
    catch {
        $result.Error = "Failed to retrieve credential profiles: $($_.Exception.Message)"
        Write-CredLog -Level Error -Message $result.Error
    }

    return $result
}

<#
.SYNOPSIS
    Retrieves all credential profiles.

.DESCRIPTION
    Gets all saved credential profiles with summary information.

.EXAMPLE
    Get-AllCredentialProfiles

.OUTPUTS
    [PSCustomObject] Result with Success, Data (all profiles), and Error.
#>
function Get-AllCredentialProfiles {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    return Get-CredentialProfile
}

<#
.SYNOPSIS
    Gets the appropriate credential for a machine tier.

.DESCRIPTION
    Returns a PSCredential object for the specified tier.
    Uses the default credential for that tier, or the first available.

.PARAMETER Tier
    Machine tier: 0 (DC), 1 (Server), 2 (Workstation).

.PARAMETER ProfileName
    Specific profile name to use instead of default.

.EXAMPLE
    $cred = Get-CredentialForTier -Tier 1
    Invoke-Command -ComputerName 'Server01' -Credential $cred.Data -ScriptBlock { ... }

.OUTPUTS
    [PSCustomObject] Result with Success, Data (PSCredential), and Error.

.NOTES
    Returns decrypted PSCredential object for use in remoting.
#>
function Get-CredentialForTier {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(0, 1, 2)]
        [int]$Tier,

        [Parameter()]
        [string]$ProfileName
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    try {
        #region --- Get Profile ---
        $profile = $null

        if ($ProfileName) {
            $profileResult = Get-CredentialProfile -Name $ProfileName
            if ($profileResult.Success -and $profileResult.Data) {
                $profile = $profileResult.Data
            }
        }
        else {
            # Get default for tier, or first available
            $tierProfiles = Get-CredentialProfile -Tier $Tier
            if ($tierProfiles.Success -and $tierProfiles.Data) {
                $profile = $tierProfiles.Data | Where-Object { $_.IsDefault } | Select-Object -First 1
                if (-not $profile) {
                    $profile = $tierProfiles.Data | Select-Object -First 1
                }
            }
        }
        #endregion

        if (-not $profile) {
            $result.Error = "No credential profile found for Tier $Tier"
            return $result
        }

        #region --- Decrypt and Create PSCredential ---
        $securePassword = $profile.EncryptedPassword | ConvertTo-SecureString
        $credential = [System.Management.Automation.PSCredential]::new(
            $profile.Username,
            $securePassword
        )
        #endregion

        #region --- Update Last Used ---
        $credPath = Get-CredentialStoragePath
        $profilePath = Join-Path $credPath "$($profile.Id).json"
        $profile.LastUsed = (Get-Date).ToString('o')
        $profile | ConvertTo-Json -Depth 5 | Set-Content -Path $profilePath -Encoding UTF8
        #endregion

        $result.Success = $true
        $result.Data = $credential
    }
    catch {
        $result.Error = "Failed to get credential for tier: $($_.Exception.Message)"
        Write-CredLog -Level Error -Message $result.Error
    }

    return $result
}
