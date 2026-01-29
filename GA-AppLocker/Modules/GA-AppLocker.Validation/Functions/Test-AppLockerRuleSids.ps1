function Test-AppLockerRuleSids {
    <#
    .SYNOPSIS
        Validates all Security Identifiers (SIDs) in AppLocker rules.

    .DESCRIPTION
        Ensures UserOrGroupSid values are:
        - Present on every rule
        - Valid SID format (S-1-...)
        - Optionally resolvable to a security principal

    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.

    .PARAMETER ResolveNames
        If specified, attempts to resolve SIDs to account names.

    .OUTPUTS
        [PSCustomObject] with Success, Errors, UnresolvedSids, SidMappings properties

    .EXAMPLE
        Test-AppLockerRuleSids -XmlPath "C:\Policies\baseline.xml"

    .EXAMPLE
        Test-AppLockerRuleSids -XmlPath "C:\Policies\baseline.xml" -ResolveNames
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath,

        [switch]$ResolveNames
    )

    $result = [PSCustomObject]@{
        Success        = $false
        Errors         = [System.Collections.ArrayList]::new()
        UnresolvedSids = [System.Collections.ArrayList]::new()
        SidMappings    = [System.Collections.ArrayList]::new()
    }

    # Well-known SIDs that are always valid
    $wellKnownSids = @{
        'S-1-1-0'      = 'Everyone'
        'S-1-5-18'     = 'SYSTEM'
        'S-1-5-19'     = 'LOCAL SERVICE'
        'S-1-5-20'     = 'NETWORK SERVICE'
        'S-1-5-32-544' = 'Administrators'
        'S-1-5-32-545' = 'Users'
        'S-1-5-32-547' = 'Power Users'
    }

    $sidPattern = '^S-1-\d+(-\d+)+$'

    try {
        [xml]$policy = Get-Content $XmlPath -Raw

        foreach ($collection in $policy.AppLockerPolicy.RuleCollection) {
            $collectionType = $collection.Type

            $rules = @()
            $rules += $collection.FilePublisherRule
            $rules += $collection.FileHashRule
            $rules += $collection.FilePathRule

            foreach ($rule in $rules) {
                if (-not $rule) { continue }

                $sid = $rule.UserOrGroupSid
                $name = $rule.Name

                if ([string]::IsNullOrEmpty($sid)) {
                    [void]$result.Errors.Add("[$collectionType] Rule '$name' missing UserOrGroupSid")
                    continue
                }

                # Validate SID format
                if ($sid -notmatch $sidPattern) {
                    [void]$result.Errors.Add("[$collectionType] Rule '$name' has invalid SID format: $sid")
                    continue
                }

                # Attempt resolution
                $accountName = $null
                if ($wellKnownSids.ContainsKey($sid)) {
                    $accountName = $wellKnownSids[$sid]
                }
                elseif ($ResolveNames) {
                    try {
                        $sidObj = New-Object System.Security.Principal.SecurityIdentifier($sid)
                        $accountName = $sidObj.Translate([System.Security.Principal.NTAccount]).Value
                    }
                    catch {
                        [void]$result.UnresolvedSids.Add("[$collectionType] Rule '$name': $sid")
                    }
                }

                [void]$result.SidMappings.Add([PSCustomObject]@{
                    Collection  = $collectionType
                    RuleName    = $name
                    Sid         = $sid
                    AccountName = $accountName
                })
            }
        }

        $result.Success = ($result.Errors.Count -eq 0)
    }
    catch {
        [void]$result.Errors.Add("SID validation failed: $($_.Exception.Message)")
    }

    return $result
}
