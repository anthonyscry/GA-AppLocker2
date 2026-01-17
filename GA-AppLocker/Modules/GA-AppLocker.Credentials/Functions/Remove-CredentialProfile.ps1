<#
.SYNOPSIS
    Removes a credential profile from storage.

.DESCRIPTION
    Deletes a saved credential profile by name or ID.

.PARAMETER Name
    Name of the credential profile to remove.

.PARAMETER Id
    GUID of the credential profile to remove.

.PARAMETER Force
    Skip confirmation prompt.

.EXAMPLE
    Remove-CredentialProfile -Name 'OldAdmin'

.EXAMPLE
    Remove-CredentialProfile -Id '12345678-1234-1234-1234-123456789012' -Force

.OUTPUTS
    [PSCustomObject] Result with Success and Error.

.NOTES
    Author: GA-AppLocker Team
    Version: 1.0.0
#>
function Remove-CredentialProfile {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByName', Mandatory)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ById', Mandatory)]
        [string]$Id,

        [Parameter()]
        [switch]$Force
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    try {
        #region --- Find Profile ---
        $profile = $null

        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $profileResult = Get-CredentialProfile -Name $Name
            if ($profileResult.Success -and $profileResult.Data) {
                $profile = $profileResult.Data
            }
        }
        else {
            $profileResult = Get-CredentialProfile -Id $Id
            if ($profileResult.Success -and $profileResult.Data) {
                $profile = $profileResult.Data
            }
        }

        if (-not $profile) {
            $result.Error = "Credential profile not found"
            return $result
        }
        #endregion

        #region --- Delete File ---
        $credPath = Get-CredentialStoragePath
        $profilePath = Join-Path $credPath "$($profile.Id).json"

        if (Test-Path $profilePath) {
            Remove-Item -Path $profilePath -Force
            $result.Success = $true
            Write-CredLog -Message "Removed credential profile: $($profile.Name)"
        }
        else {
            $result.Error = "Profile file not found"
        }
        #endregion
    }
    catch {
        $result.Error = "Failed to remove credential profile: $($_.Exception.Message)"
        Write-CredLog -Level Error -Message $result.Error
    }

    return $result
}
