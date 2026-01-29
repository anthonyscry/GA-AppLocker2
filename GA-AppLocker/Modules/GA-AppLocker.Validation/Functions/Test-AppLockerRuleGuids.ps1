function Test-AppLockerRuleGuids {
    <#
    .SYNOPSIS
        Validates all rule GUIDs in an AppLocker policy.

    .DESCRIPTION
        Ensures all rule IDs are:
        - Valid GUID format (8-4-4-4-12)
        - Uppercase (AppLocker requirement)
        - Unique across all rule collections

    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.

    .OUTPUTS
        [PSCustomObject] with Success, Errors, DuplicateGuids, TotalGuids, UniqueGuids properties

    .EXAMPLE
        Test-AppLockerRuleGuids -XmlPath "C:\Policies\baseline.xml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath
    )

    $result = [PSCustomObject]@{
        Success        = $false
        Errors         = [System.Collections.ArrayList]::new()
        DuplicateGuids = [System.Collections.ArrayList]::new()
        TotalGuids     = 0
        UniqueGuids    = 0
    }

    try {
        [xml]$policy = Get-Content $XmlPath -Raw
        $allGuids = [System.Collections.ArrayList]::new()
        $guidPattern = '^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$'

        foreach ($collection in $policy.AppLockerPolicy.RuleCollection) {
            $collectionType = $collection.Type

            # Get all rule types
            $rules = @()
            $rules += $collection.FilePublisherRule
            $rules += $collection.FileHashRule
            $rules += $collection.FilePathRule

            foreach ($rule in $rules) {
                if (-not $rule) { continue }

                $id = $rule.Id
                $name = $rule.Name

                # Check GUID format
                if ([string]::IsNullOrEmpty($id)) {
                    [void]$result.Errors.Add("[$collectionType] Rule '$name' has no Id attribute")
                    continue
                }

                # Validate format (case-sensitive: AppLocker requires uppercase GUIDs)
                if ($id -cnotmatch $guidPattern) {
                    # Check if it's valid but lowercase
                    if ($id.ToUpper() -cmatch $guidPattern) {
                        [void]$result.Errors.Add("[$collectionType] Rule '$name' GUID must be UPPERCASE: $id")
                    }
                    else {
                        [void]$result.Errors.Add("[$collectionType] Rule '$name' has invalid GUID format: $id")
                    }
                }

                # Track for duplicates
                [void]$allGuids.Add([PSCustomObject]@{
                    Guid       = $id
                    Collection = $collectionType
                    RuleName   = $name
                })
            }
        }

        $result.TotalGuids = $allGuids.Count

        # Check for duplicates
        $grouped = $allGuids | Group-Object Guid | Where-Object Count -gt 1
        foreach ($group in $grouped) {
            $locations = ($group.Group | ForEach-Object { "[$($_.Collection)] $($_.RuleName)" }) -join ', '
            [void]$result.DuplicateGuids.Add("GUID $($group.Name) used in: $locations")
            [void]$result.Errors.Add("Duplicate GUID found: $($group.Name)")
        }

        $result.UniqueGuids = ($allGuids | Select-Object -Unique Guid).Count
        $result.Success = ($result.Errors.Count -eq 0)
    }
    catch {
        [void]$result.Errors.Add("GUID validation failed: $($_.Exception.Message)")
    }

    return $result
}
