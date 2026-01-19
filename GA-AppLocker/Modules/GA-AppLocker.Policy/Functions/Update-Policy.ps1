function Update-Policy {
    <#
    .SYNOPSIS
        Updates an existing AppLocker policy.

    .DESCRIPTION
        Updates policy properties like enforcement mode and phase.

    .PARAMETER Id
        The policy GUID to update.

    .PARAMETER EnforcementMode
        The enforcement mode: NotConfigured, AuditOnly, or Enabled.

    .PARAMETER Phase
        The deployment phase (1-4).

    .EXAMPLE
        Update-Policy -Id "12345..." -EnforcementMode "Enabled" -Phase 4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [ValidateSet('NotConfigured', 'AuditOnly', 'Enabled')]
        [string]$EnforcementMode,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4)]
        [int]$Phase
    )

    try {
        $dataPath = Get-AppLockerDataPath
        $policiesPath = Join-Path $dataPath 'Policies'
        $policyFile = Join-Path $policiesPath "$Id.json"

        if (-not (Test-Path $policyFile)) {
            return @{
                Success = $false
                Error   = "Policy not found: $Id"
            }
        }

        $policy = Get-Content -Path $policyFile -Raw | ConvertFrom-Json

        # Update enforcement mode if provided
        if ($PSBoundParameters.ContainsKey('EnforcementMode')) {
            # SAFETY RULE: Phase 1-3 ALWAYS use AuditOnly
            $effectivePhase = if ($PSBoundParameters.ContainsKey('Phase')) { $Phase } else { $policy.Phase }
            if ($effectivePhase -lt 4 -and $EnforcementMode -eq 'Enabled') {
                $policy.EnforcementMode = 'AuditOnly'
            } else {
                $policy.EnforcementMode = $EnforcementMode
            }
        }

        # Update phase if provided
        if ($PSBoundParameters.ContainsKey('Phase')) {
            $policy.Phase = $Phase
            # Apply safety rule for phase change
            if ($Phase -lt 4) {
                $policy.EnforcementMode = 'AuditOnly'
            }
        }

        # Update modification timestamp
        $policy.ModifiedAt = (Get-Date).ToString('o')
        $currentVersion = if ($policy.Version) { [int]$policy.Version } else { 0 }
        $policy.Version = $currentVersion + 1

        $policy | ConvertTo-Json -Depth 5 | Set-Content -Path $policyFile -Encoding UTF8

        return @{
            Success = $true
            Data    = $policy
            Message = "Policy updated successfully"
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
