function New-Policy {
    <#
    .SYNOPSIS
        Creates a new AppLocker policy.

    .DESCRIPTION
        Creates a policy that can contain multiple rules and be
        targeted to specific OUs or GPOs.

    .PARAMETER Name
        The name of the policy.

    .PARAMETER Description
        Optional description of the policy.

    .PARAMETER EnforcementMode
        The enforcement mode: NotConfigured, AuditOnly, or Enabled.

    .PARAMETER RuleIds
        Optional array of rule IDs to include in the policy.

    .EXAMPLE
        New-Policy -Name "Baseline Policy" -EnforcementMode "AuditOnly"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description = '',

        [Parameter(Mandatory = $false)]
        [ValidateSet('NotConfigured', 'AuditOnly', 'Enabled')]
        [string]$EnforcementMode = 'AuditOnly',

        [Parameter(Mandatory = $false)]
        [string[]]$RuleIds = @()
    )

    try {
        $dataPath = Get-AppLockerDataPath
        $policiesPath = Join-Path $dataPath 'Policies'

        if (-not (Test-Path $policiesPath)) {
            New-Item -Path $policiesPath -ItemType Directory -Force | Out-Null
        }

        $policyId = [guid]::NewGuid().ToString()

        $policy = [PSCustomObject]@{
            PolicyId        = $policyId
            Name            = $Name
            Description     = $Description
            EnforcementMode = $EnforcementMode
            Status          = 'Draft'
            RuleIds         = @($RuleIds)
            TargetOUs       = @()
            TargetGPO       = $null
            CreatedAt       = (Get-Date).ToString('o')
            ModifiedAt      = (Get-Date).ToString('o')
            CreatedBy       = $env:USERNAME
            Version         = 1
        }

        $policyFile = Join-Path $policiesPath "$policyId.json"
        $policy | ConvertTo-Json -Depth 5 | Set-Content -Path $policyFile -Encoding UTF8

        return @{
            Success = $true
            Data    = $policy
            Message = "Policy '$Name' created successfully"
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
