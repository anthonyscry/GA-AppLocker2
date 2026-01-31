<#
.SYNOPSIS
    Tests a credential profile against a target machine.

.DESCRIPTION
    Validates that a credential profile can successfully authenticate
    to a target machine via WinRM.

.PARAMETER Name
    Name of the credential profile to test.

.PARAMETER ComputerName
    Target machine to test against.

.EXAMPLE
    Test-CredentialProfile -Name 'DomainAdmin' -ComputerName 'DC01'

.OUTPUTS
    [PSCustomObject] Result with Success, Data (test details), and Error.

.NOTES
    Author: GA-AppLocker Team
    Version: 1.0.0
#>
function Test-CredentialProfile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    try {
        #region --- Get Profile and Credential ---
        $profileResult = Get-CredentialProfile -Name $Name
        if (-not $profileResult.Success -or -not $profileResult.Data) {
            $result.Error = "Credential profile '$Name' not found"
            return $result
        }

        $profile = $profileResult.Data
        $credResult = Get-CredentialForTier -Tier $profile.Tier -ProfileName $Name

        if (-not $credResult.Success) {
            $result.Error = "Failed to decrypt credential: $($credResult.Error)"
            return $result
        }

        $credential = $credResult.Data
        #endregion

        #region --- Test Connection ---
        $testResult = [PSCustomObject]@{
            ProfileName  = $Name
            ComputerName = $ComputerName
            Username     = $profile.Username
            TestTime     = Get-Date
            PingSuccess  = $false
            WinRMSuccess = $false
            ErrorMessage = $null
        }

        # Ping test using WMI Win32_PingStatus (consistent with Test-PingConnectivity, avoids
        # Test-Connection which can be unreliable in constrained environments)
        try {
            $ping = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$ComputerName' AND Timeout=2000" -ErrorAction Stop
            $pingResult = ($null -ne $ping -and $ping.StatusCode -eq 0)
        }
        catch {
            $pingResult = $false
        }
        $testResult.PingSuccess = $pingResult

        if (-not $pingResult) {
            $testResult.ErrorMessage = "Host unreachable"
        }
        else {
            # WinRM test with credential
            try {
                $session = New-PSSession -ComputerName $ComputerName -Credential $credential -ErrorAction Stop
                Remove-PSSession -Session $session
                $testResult.WinRMSuccess = $true
            }
            catch {
                $testResult.ErrorMessage = "WinRM failed: $($_.Exception.Message)"
            }
        }
        #endregion

        #region --- Update Profile with Test Result ---
        $credPath = Get-CredentialStoragePath
        $profilePath = Join-Path $credPath "$($profile.Id).json"

        $profile.LastTestResult = [PSCustomObject]@{
            ComputerName = $ComputerName
            Success      = $testResult.WinRMSuccess
            TestTime     = $testResult.TestTime.ToString('o')
            Error        = $testResult.ErrorMessage
        }

        $profile | ConvertTo-Json -Depth 5 | Set-Content -Path $profilePath -Encoding UTF8
        #endregion

        $result.Success = $testResult.WinRMSuccess
        $result.Data = $testResult

        $status = if ($testResult.WinRMSuccess) { 'passed' } else { 'failed' }
        Write-CredLog -Message "Credential test $status for '$Name' on $ComputerName"
    }
    catch {
        $result.Error = "Credential test failed: $($_.Exception.Message)"
        Write-CredLog -Level Error -Message $result.Error
    }

    return $result
}
