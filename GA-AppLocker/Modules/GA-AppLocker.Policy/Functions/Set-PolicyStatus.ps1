function Set-PolicyStatus {
    <#
    .SYNOPSIS
        Updates the status of a policy.


.DESCRIPTION
    Updates the status of a policy. Persists the change to the local GA-AppLocker data store under %LOCALAPPDATA%\GA-AppLocker.

    .PARAMETER PolicyId
        The unique identifier of the policy.

    .PARAMETER Status
        The new status: Draft, Active, Deployed, or Archived.

    .EXAMPLE
        Set-PolicyStatus -PolicyId "abc123" -Status "Active"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Draft', 'Active', 'Deployed', 'Archived')]
        [string]$Status
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

        $oldStatus = $policy.Status
        $policy.Status = $Status
        $policy.ModifiedAt = (Get-Date).ToString('o')
        $policy.Version = $policy.Version + 1

        $policy | ConvertTo-Json -Depth 5 | Set-Content -Path $policyFile -Encoding UTF8
        
        # Write audit log
        if (Get-Command -Name 'Write-AuditLog' -ErrorAction SilentlyContinue) {
            Write-AuditLog -Action "Policy$Status" -Category 'Policy' -Target $policy.Name -TargetId $PolicyId `
                -Details "Policy status changed from $oldStatus to $Status" -OldValue $oldStatus -NewValue $Status
        }

        return @{
            Success = $true
            Data    = $policy
            Message = "Policy status updated to '$Status'"
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

function Remove-Policy {
    <#
    .SYNOPSIS
        Removes a policy.


.DESCRIPTION
    Removes a policy.

    .PARAMETER PolicyId
        The unique identifier of the policy to remove.

    .PARAMETER Force
        Force removal even if policy is deployed.

    .EXAMPLE
        Remove-Policy -PolicyId "abc123"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyId,

        [Parameter(Mandatory = $false)]
        [switch]$Force
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

        if ($policy.Status -eq 'Deployed' -and -not $Force) {
            return @{
                Success = $false
                Error   = "Cannot remove deployed policy. Use -Force to override."
            }
        }

        Remove-Item -Path $policyFile -Force
        
        # Write audit log
        if (Get-Command -Name 'Write-AuditLog' -ErrorAction SilentlyContinue) {
            Write-AuditLog -Action 'PolicyDeleted' -Category 'Policy' -Target $policy.Name -TargetId $PolicyId `
                -Details "Policy removed (Force: $Force)"
        }

        return @{
            Success = $true
            Message = "Policy '$($policy.Name)' removed"
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
