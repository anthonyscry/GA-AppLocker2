function Set-PolicyTarget {
    <#
    .SYNOPSIS
        Sets the target OUs or GPO for a policy.


.DESCRIPTION
    Sets the target OUs or GPO for a policy. Persists the change to the local GA-AppLocker data store under %LOCALAPPDATA%\GA-AppLocker.

    .PARAMETER PolicyId
        The unique identifier of the policy.

    .PARAMETER TargetOUs
        Array of OU distinguished names to target.

    .PARAMETER TargetGPO
        The name of the GPO to deploy to.

    .EXAMPLE
        Set-PolicyTarget -PolicyId "abc123" -TargetOUs @("OU=Workstations,DC=domain,DC=com")
        Set-PolicyTarget -PolicyId "abc123" -TargetGPO "AppLocker-Workstations"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyId,

        [Parameter(Mandatory = $false)]
        [string[]]$TargetOUs,

        [Parameter(Mandatory = $false)]
        [string]$TargetGPO
    )

    try {
        $dataPath = Get-AppLockerDataPath
        $policiesPath = Join-Path $dataPath 'Policies'
        $policyFile = Join-Path $policiesPath "$PolicyId.json"

        if (-not (Test-Path $policyFile)) {
            return @{
                Success = $false
                Error   = "Policy not found: $PolicyId"
            }
        }

        $policy = Get-Content -Path $policyFile -Raw | ConvertFrom-Json

        if ($PSBoundParameters.ContainsKey('TargetOUs')) {
            $policy.TargetOUs = @($TargetOUs)
        }

        if ($PSBoundParameters.ContainsKey('TargetGPO')) {
            $policy.TargetGPO = $TargetGPO
        }

        $policy.ModifiedAt = (Get-Date).ToString('o')
        $currentVersion = if ($policy.Version) { [int]$policy.Version } else { 0 }
        $policy.Version = $currentVersion + 1

        $policy | ConvertTo-Json -Depth 5 | Set-Content -Path $policyFile -Encoding UTF8

        # Update policy index
        try {
            Initialize-PolicyIndex
            $indexEntry = [PSCustomObject]@{
                PolicyId        = $policy.PolicyId
                Name            = $policy.Name
                Description     = $policy.Description
                EnforcementMode = $policy.EnforcementMode
                Phase           = $policy.Phase
                Status          = $policy.Status
                RuleIds         = @($policy.RuleIds)
                TargetOUs       = if ($policy.TargetOUs) { @($policy.TargetOUs) } else { @() }
                TargetGPO       = $policy.TargetGPO
                CreatedAt       = $policy.CreatedAt
                ModifiedAt      = $policy.ModifiedAt
                Version         = $policy.Version
                FilePath        = $policyFile
            }
            $null = Add-PolicyIndexEntry -Entry $indexEntry -SkipSave
            Save-PolicyIndex
        }
        catch {
            # Index update failure should not block target update
            Write-PolicyLog -Message "Failed to update policy index for target change: $($_.Exception.Message)" -Level 'WARNING'
        }

        return @{
            Success = $true
            Data    = $policy
            Message = "Policy targets updated"
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
