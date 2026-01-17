<#
.SYNOPSIS
    Creates a new credential profile for GA-AppLocker scanning.

.DESCRIPTION
    Saves a credential profile with tier assignment for use during
    machine scanning. Credentials are encrypted using Windows DPAPI.

.PARAMETER Name
    Unique name for the credential profile.

.PARAMETER Credential
    PSCredential object containing username and password.

.PARAMETER Tier
    Machine tier this credential is for: 0 (DC), 1 (Server), 2 (Workstation).

.PARAMETER Description
    Optional description for the credential profile.

.PARAMETER SetAsDefault
    Set this credential as the default for its tier.

.EXAMPLE
    $cred = Get-Credential
    New-CredentialProfile -Name 'DomainAdmin' -Credential $cred -Tier 0

.EXAMPLE
    New-CredentialProfile -Name 'ServerAdmin' -Credential $cred -Tier 1 -SetAsDefault

.OUTPUTS
    [PSCustomObject] Result with Success, Data (profile), and Error.

.NOTES
    Author: GA-AppLocker Team
    Version: 1.0.0
#>
function New-CredentialProfile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory)]
        [ValidateSet(0, 1, 2)]
        [int]$Tier,

        [Parameter()]
        [string]$Description = '',

        [Parameter()]
        [switch]$SetAsDefault
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    try {
        #region --- Validate Name Uniqueness ---
        $existing = Get-CredentialProfile -Name $Name
        if ($existing.Success -and $existing.Data) {
            $result.Error = "Credential profile '$Name' already exists"
            return $result
        }
        #endregion

        #region --- Encrypt Credential ---
        $encryptedPassword = $Credential.Password | ConvertFrom-SecureString
        #endregion

        #region --- Build Profile Object ---
        $profile = [PSCustomObject]@{
            Id              = [guid]::NewGuid().ToString()
            Name            = $Name
            Username        = $Credential.UserName
            EncryptedPassword = $encryptedPassword
            Tier            = $Tier
            TierName        = $script:CredentialTiers[$Tier]
            Description     = $Description
            IsDefault       = $SetAsDefault.IsPresent
            CreatedDate     = (Get-Date).ToString('o')
            LastUsed        = $null
            LastTestResult  = $null
        }
        #endregion

        #region --- Save to File ---
        $credPath = Get-CredentialStoragePath
        $profilePath = Join-Path $credPath "$($profile.Id).json"

        # If setting as default, clear other defaults for this tier
        if ($SetAsDefault) {
            Clear-TierDefault -Tier $Tier
        }

        $profile | ConvertTo-Json -Depth 5 | Set-Content -Path $profilePath -Encoding UTF8
        #endregion

        $result.Success = $true
        $result.Data = $profile

        Write-CredLog -Message "Created credential profile: $Name (Tier $Tier)"
    }
    catch {
        $result.Error = "Failed to create credential profile: $($_.Exception.Message)"
        Write-CredLog -Level Error -Message $result.Error
    }

    return $result
}

#region ===== HELPER FUNCTIONS =====
function Get-CredentialStoragePath {
    $dataPath = Get-AppLockerDataPath
    $credPath = Join-Path $dataPath 'Credentials'

    if (-not (Test-Path $credPath)) {
        New-Item -Path $credPath -ItemType Directory -Force | Out-Null
    }

    return $credPath
}

function Clear-TierDefault {
    param([int]$Tier)

    $credPath = Get-CredentialStoragePath
    $profiles = Get-ChildItem -Path $credPath -Filter '*.json' -ErrorAction SilentlyContinue

    foreach ($file in $profiles) {
        $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        if ($content.Tier -eq $Tier -and $content.IsDefault) {
            $content.IsDefault = $false
            $content | ConvertTo-Json -Depth 5 | Set-Content -Path $file.FullName -Encoding UTF8
        }
    }
}
#endregion
