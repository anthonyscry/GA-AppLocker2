function Get-Policy {
    <#
    .SYNOPSIS
        Retrieves a policy by ID or name.

    .PARAMETER PolicyId
        The unique identifier of the policy.

    .PARAMETER Name
        The name of the policy to find.

    .EXAMPLE
        Get-Policy -PolicyId "abc123"
        Get-Policy -Name "Baseline Policy"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PolicyId,

        [Parameter(Mandatory = $false)]
        [string]$Name
    )

    try {
        $dataPath = Get-AppLockerDataPath
        $policiesPath = Join-Path $dataPath 'Policies'

        if (-not (Test-Path $policiesPath)) {
            return @{
                Success = $true
                Data    = $null
                Message = 'No policies found'
            }
        }

        if ($PolicyId) {
            $policyFile = Join-Path $policiesPath "$PolicyId.json"
            if (Test-Path $policyFile) {
                $policy = Get-Content -Path $policyFile -Raw | ConvertFrom-Json
                return @{
                    Success = $true
                    Data    = $policy
                }
            }
            return @{
                Success = $false
                Error   = "Policy not found: $PolicyId"
            }
        }

        if ($Name) {
            $policyFiles = Get-ChildItem -Path $policiesPath -Filter '*.json' -File
            foreach ($file in $policyFiles) {
                $policy = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                if ($policy.Name -eq $Name) {
                    return @{
                        Success = $true
                        Data    = $policy
                    }
                }
            }
            return @{
                Success = $false
                Error   = "Policy not found: $Name"
            }
        }

        return @{
            Success = $false
            Error   = 'Please specify PolicyId or Name'
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

function Get-AllPolicies {
    <#
    .SYNOPSIS
        Retrieves all policies.

    .PARAMETER Status
        Optional filter by status (Draft, Active, Deployed, Archived).

    .EXAMPLE
        Get-AllPolicies
        Get-AllPolicies -Status "Active"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Draft', 'Active', 'Deployed', 'Archived', '')]
        [string]$Status = ''
    )

    try {
        $dataPath = Get-AppLockerDataPath
        $policiesPath = Join-Path $dataPath 'Policies'

        if (-not (Test-Path $policiesPath)) {
            return @{
                Success = $true
                Data    = @()
            }
        }

        $policyFiles = Get-ChildItem -Path $policiesPath -Filter '*.json' -File
        $policies = @()

        foreach ($file in $policyFiles) {
            $policy = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            if ([string]::IsNullOrEmpty($Status) -or $policy.Status -eq $Status) {
                $policies += $policy
            }
        }

        # Sort by modified date descending
        $policies = $policies | Sort-Object -Property ModifiedAt -Descending

        return @{
            Success = $true
            Data    = $policies
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
