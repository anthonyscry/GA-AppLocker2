<#
.SYNOPSIS
    Functions for comparing AppLocker policies and detecting differences.

.DESCRIPTION
    Provides functions to compare two policies and identify added, removed, and modified rules.
    Useful for reviewing changes before deployment or auditing policy drift.


    .EXAMPLE
    Compare-Policies
    # Compare Policies
    #>

function Compare-Policies {
    <#
    .SYNOPSIS
        Compares two AppLocker policies and returns differences.

    .DESCRIPTION
        Analyzes two policies and identifies:
        - Rules that exist only in the source policy (will be removed if target becomes baseline)
        - Rules that exist only in the target policy (newly added)
        - Rules that exist in both but have been modified
        - Rules that are identical in both

    .PARAMETER SourcePolicyId
        The ID of the source/baseline policy.

    .PARAMETER TargetPolicyId
        The ID of the target/comparison policy.

    .PARAMETER SourcePolicy
        Optional. A policy object instead of ID for source.

    .PARAMETER TargetPolicy
        Optional. A policy object instead of ID for target.

    .PARAMETER IncludeUnchanged
        If specified, includes unchanged rules in the output.

    .EXAMPLE
        Compare-Policies -SourcePolicyId "abc123" -TargetPolicyId "def456"
        Compares two policies by ID.

    .EXAMPLE
        $diff = Compare-Policies -SourcePolicy $oldPolicy -TargetPolicy $newPolicy
        Compares two policy objects directly.

    .OUTPUTS
        [PSCustomObject] Comparison result with Success, Data (Added, Removed, Modified, Unchanged), and Error.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SourcePolicyId,

        [Parameter(Mandatory = $false)]
        [string]$TargetPolicyId,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$SourcePolicy,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$TargetPolicy,

        [Parameter()]
        [switch]$IncludeUnchanged
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    try {
        # Get source policy
        if ($SourcePolicy) {
            $source = $SourcePolicy
        }
        elseif ($SourcePolicyId) {
            $sourceResult = Get-Policy -PolicyId $SourcePolicyId
            if (-not $sourceResult.Success) {
                throw "Source policy not found: $SourcePolicyId"
            }
            $source = $sourceResult.Data
        }
        else {
            throw "Either SourcePolicyId or SourcePolicy must be specified"
        }

        # Get target policy
        if ($TargetPolicy) {
            $target = $TargetPolicy
        }
        elseif ($TargetPolicyId) {
            $targetResult = Get-Policy -PolicyId $TargetPolicyId
            if (-not $targetResult.Success) {
                throw "Target policy not found: $TargetPolicyId"
            }
            $target = $targetResult.Data
        }
        else {
            throw "Either TargetPolicyId or TargetPolicy must be specified"
        }

        # Get rules from each policy
        $sourceRules = @{}
        $targetRules = @{}

        # Index source rules by ID
        if ($source.RuleIds) {
            foreach ($ruleId in $source.RuleIds) {
                $ruleResult = Get-Rule -Id $ruleId
                if ($ruleResult.Success) {
                    $sourceRules[$ruleId] = $ruleResult.Data
                }
            }
        }

        # Index target rules by ID
        if ($target.RuleIds) {
            foreach ($ruleId in $target.RuleIds) {
                $ruleResult = Get-Rule -Id $ruleId
                if ($ruleResult.Success) {
                    $targetRules[$ruleId] = $ruleResult.Data
                }
            }
        }

        # Find differences
        $added = @()
        $removed = @()
        $modified = @()
        $unchanged = @()

        # Rules in target but not in source (added)
        foreach ($ruleId in $targetRules.Keys) {
            if (-not $sourceRules.ContainsKey($ruleId)) {
                $added += [PSCustomObject]@{
                    RuleId   = $ruleId
                    Rule     = $targetRules[$ruleId]
                    Change   = 'Added'
                }
            }
        }

        # Rules in source but not in target (removed)
        foreach ($ruleId in $sourceRules.Keys) {
            if (-not $targetRules.ContainsKey($ruleId)) {
                $removed += [PSCustomObject]@{
                    RuleId   = $ruleId
                    Rule     = $sourceRules[$ruleId]
                    Change   = 'Removed'
                }
            }
        }

        # Rules in both - check for modifications
        foreach ($ruleId in $sourceRules.Keys) {
            if ($targetRules.ContainsKey($ruleId)) {
                $sourceRule = $sourceRules[$ruleId]
                $targetRule = $targetRules[$ruleId]

                $changes = Compare-RuleProperties -SourceRule $sourceRule -TargetRule $targetRule

                if ($changes.Count -gt 0) {
                    $modified += [PSCustomObject]@{
                        RuleId        = $ruleId
                        SourceRule    = $sourceRule
                        TargetRule    = $targetRule
                        Changes       = $changes
                        Change        = 'Modified'
                    }
                }
                elseif ($IncludeUnchanged) {
                    $unchanged += [PSCustomObject]@{
                        RuleId   = $ruleId
                        Rule     = $sourceRule
                        Change   = 'Unchanged'
                    }
                }
            }
        }

        $result.Data = [PSCustomObject]@{
            SourcePolicy     = [PSCustomObject]@{
                Id   = $source.PolicyId
                Name = $source.Name
            }
            TargetPolicy     = [PSCustomObject]@{
                Id   = $target.PolicyId
                Name = $target.Name
            }
            Summary          = [PSCustomObject]@{
                TotalSourceRules = $sourceRules.Count
                TotalTargetRules = $targetRules.Count
                AddedCount       = $added.Count
                RemovedCount     = $removed.Count
                ModifiedCount    = $modified.Count
                UnchangedCount   = if ($IncludeUnchanged) { $unchanged.Count } else { $sourceRules.Count - $removed.Count - $modified.Count }
            }
            Added            = $added
            Removed          = $removed
            Modified         = $modified
            Unchanged        = if ($IncludeUnchanged) { $unchanged } else { @() }
            HasDifferences   = ($added.Count -gt 0) -or ($removed.Count -gt 0) -or ($modified.Count -gt 0)
        }

        $result.Success = $true
        Write-PolicyLog -Message "Compared policies: $($source.Name) vs $($target.Name) - $($added.Count) added, $($removed.Count) removed, $($modified.Count) modified"
    }
    catch {
        $result.Error = "Failed to compare policies: $($_.Exception.Message)"
        Write-PolicyLog -Level Error -Message $result.Error
    }

    return $result
}

function Compare-RuleProperties {
    <#
    .SYNOPSIS
        Compares two rules and returns list of changed properties.

    .DESCRIPTION
        Helper function that compares rule properties and returns which ones differ.

    .PARAMETER SourceRule
        The source/original rule.

    .PARAMETER TargetRule
        The target/modified rule.

    .OUTPUTS
        [Array] List of property change objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$SourceRule,

        [Parameter(Mandatory)]
        [PSCustomObject]$TargetRule
    )

    $changes = @()
    $propsToCompare = @('Name', 'Action', 'Status', 'RuleType', 'CollectionType', 
                        'UserOrGroupSid', 'PublisherName', 'ProductName', 'BinaryName',
                        'MinVersion', 'MaxVersion', 'Hash', 'Path', 'Description')

    foreach ($prop in $propsToCompare) {
        $sourceValue = $SourceRule.$prop
        $targetValue = $TargetRule.$prop

        # Handle null comparisons
        $sourceIsNull = $null -eq $sourceValue -or [string]::IsNullOrEmpty($sourceValue)
        $targetIsNull = $null -eq $targetValue -or [string]::IsNullOrEmpty($targetValue)

        if ($sourceIsNull -and $targetIsNull) {
            continue
        }

        if ($sourceValue -ne $targetValue) {
            $changes += [PSCustomObject]@{
                Property    = $prop
                OldValue    = $sourceValue
                NewValue    = $targetValue
            }
        }
    }

    return $changes
}

function Get-PolicyDiffReport {
    <#
    .SYNOPSIS
        Generates a human-readable diff report between two policies.

    .DESCRIPTION
        Creates a formatted text report showing all differences between policies.
        Useful for review meetings or audit documentation.

    .PARAMETER SourcePolicyId
        The ID of the source/baseline policy.

    .PARAMETER TargetPolicyId
        The ID of the target/comparison policy.

    .PARAMETER Format
        Output format: Text, Html, or Markdown. Default is Text.

    .EXAMPLE
        Get-PolicyDiffReport -SourcePolicyId "abc123" -TargetPolicyId "def456"

    .EXAMPLE
        Get-PolicyDiffReport -SourcePolicyId "abc123" -TargetPolicyId "def456" -Format Markdown

    .OUTPUTS
        [PSCustomObject] Report with Success, Data (formatted string), and Error.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePolicyId,

        [Parameter(Mandatory)]
        [string]$TargetPolicyId,

        [Parameter()]
        [ValidateSet('Text', 'Html', 'Markdown')]
        [string]$Format = 'Text'
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    try {
        $comparison = Compare-Policies -SourcePolicyId $SourcePolicyId -TargetPolicyId $TargetPolicyId -IncludeUnchanged
        if (-not $comparison.Success) {
            throw $comparison.Error
        }

        $diff = $comparison.Data
        $report = [System.Text.StringBuilder]::new()

        switch ($Format) {
            'Markdown' {
                [void]$report.AppendLine("# Policy Comparison Report")
                [void]$report.AppendLine("")
                [void]$report.AppendLine("## Summary")
                [void]$report.AppendLine("| Metric | Value |")
                [void]$report.AppendLine("|--------|-------|")
                [void]$report.AppendLine("| Source Policy | $($diff.SourcePolicy.Name) |")
                [void]$report.AppendLine("| Target Policy | $($diff.TargetPolicy.Name) |")
                [void]$report.AppendLine("| Rules Added | $($diff.Summary.AddedCount) |")
                [void]$report.AppendLine("| Rules Removed | $($diff.Summary.RemovedCount) |")
                [void]$report.AppendLine("| Rules Modified | $($diff.Summary.ModifiedCount) |")
                [void]$report.AppendLine("| Rules Unchanged | $($diff.Summary.UnchangedCount) |")
                [void]$report.AppendLine("")

                if ($diff.Added.Count -gt 0) {
                    [void]$report.AppendLine("## Added Rules")
                    foreach ($item in $diff.Added) {
                        [void]$report.AppendLine("- **$($item.Rule.Name)** ($($item.Rule.RuleType)) - $($item.Rule.Action)")
                    }
                    [void]$report.AppendLine("")
                }

                if ($diff.Removed.Count -gt 0) {
                    [void]$report.AppendLine("## Removed Rules")
                    foreach ($item in $diff.Removed) {
                        [void]$report.AppendLine("- ~~$($item.Rule.Name)~~ ($($item.Rule.RuleType)) - $($item.Rule.Action)")
                    }
                    [void]$report.AppendLine("")
                }

                if ($diff.Modified.Count -gt 0) {
                    [void]$report.AppendLine("## Modified Rules")
                    foreach ($item in $diff.Modified) {
                        [void]$report.AppendLine("### $($item.TargetRule.Name)")
                        [void]$report.AppendLine("| Property | Old Value | New Value |")
                        [void]$report.AppendLine("|----------|-----------|-----------|")
                        foreach ($change in $item.Changes) {
                            [void]$report.AppendLine("| $($change.Property) | $($change.OldValue) | $($change.NewValue) |")
                        }
                        [void]$report.AppendLine("")
                    }
                }
            }

            'Html' {
                [void]$report.AppendLine("<html><head><style>")
                [void]$report.AppendLine("body { font-family: Arial, sans-serif; margin: 20px; }")
                [void]$report.AppendLine("h1 { color: #333; } h2 { color: #666; }")
                [void]$report.AppendLine("table { border-collapse: collapse; width: 100%; margin: 10px 0; }")
                [void]$report.AppendLine("th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }")
                [void]$report.AppendLine("th { background-color: #4a90a4; color: white; }")
                [void]$report.AppendLine(".added { background-color: #d4edda; }")
                [void]$report.AppendLine(".removed { background-color: #f8d7da; }")
                [void]$report.AppendLine(".modified { background-color: #fff3cd; }")
                [void]$report.AppendLine("</style></head><body>")
                [void]$report.AppendLine("<h1>Policy Comparison Report</h1>")
                [void]$report.AppendLine("<h2>Summary</h2>")
                [void]$report.AppendLine("<table>")
                [void]$report.AppendLine("<tr><th>Metric</th><th>Value</th></tr>")
                [void]$report.AppendLine("<tr><td>Source Policy</td><td>$($diff.SourcePolicy.Name)</td></tr>")
                [void]$report.AppendLine("<tr><td>Target Policy</td><td>$($diff.TargetPolicy.Name)</td></tr>")
                [void]$report.AppendLine("<tr class='added'><td>Rules Added</td><td>$($diff.Summary.AddedCount)</td></tr>")
                [void]$report.AppendLine("<tr class='removed'><td>Rules Removed</td><td>$($diff.Summary.RemovedCount)</td></tr>")
                [void]$report.AppendLine("<tr class='modified'><td>Rules Modified</td><td>$($diff.Summary.ModifiedCount)</td></tr>")
                [void]$report.AppendLine("<tr><td>Rules Unchanged</td><td>$($diff.Summary.UnchangedCount)</td></tr>")
                [void]$report.AppendLine("</table>")

                if ($diff.Added.Count -gt 0) {
                    [void]$report.AppendLine("<h2>Added Rules</h2><ul>")
                    foreach ($item in $diff.Added) {
                        [void]$report.AppendLine("<li class='added'><strong>$($item.Rule.Name)</strong> ($($item.Rule.RuleType)) - $($item.Rule.Action)</li>")
                    }
                    [void]$report.AppendLine("</ul>")
                }

                if ($diff.Removed.Count -gt 0) {
                    [void]$report.AppendLine("<h2>Removed Rules</h2><ul>")
                    foreach ($item in $diff.Removed) {
                        [void]$report.AppendLine("<li class='removed'><del>$($item.Rule.Name)</del> ($($item.Rule.RuleType)) - $($item.Rule.Action)</li>")
                    }
                    [void]$report.AppendLine("</ul>")
                }

                if ($diff.Modified.Count -gt 0) {
                    [void]$report.AppendLine("<h2>Modified Rules</h2>")
                    foreach ($item in $diff.Modified) {
                        [void]$report.AppendLine("<h3>$($item.TargetRule.Name)</h3>")
                        [void]$report.AppendLine("<table><tr><th>Property</th><th>Old Value</th><th>New Value</th></tr>")
                        foreach ($change in $item.Changes) {
                            [void]$report.AppendLine("<tr class='modified'><td>$($change.Property)</td><td>$($change.OldValue)</td><td>$($change.NewValue)</td></tr>")
                        }
                        [void]$report.AppendLine("</table>")
                    }
                }

                [void]$report.AppendLine("</body></html>")
            }

            default {
                # Text format
                [void]$report.AppendLine("=" * 60)
                [void]$report.AppendLine("POLICY COMPARISON REPORT")
                [void]$report.AppendLine("=" * 60)
                [void]$report.AppendLine("")
                [void]$report.AppendLine("Source: $($diff.SourcePolicy.Name)")
                [void]$report.AppendLine("Target: $($diff.TargetPolicy.Name)")
                [void]$report.AppendLine("")
                [void]$report.AppendLine("-" * 40)
                [void]$report.AppendLine("SUMMARY")
                [void]$report.AppendLine("-" * 40)
                [void]$report.AppendLine("  Added:     $($diff.Summary.AddedCount)")
                [void]$report.AppendLine("  Removed:   $($diff.Summary.RemovedCount)")
                [void]$report.AppendLine("  Modified:  $($diff.Summary.ModifiedCount)")
                [void]$report.AppendLine("  Unchanged: $($diff.Summary.UnchangedCount)")
                [void]$report.AppendLine("")

                if ($diff.Added.Count -gt 0) {
                    [void]$report.AppendLine("-" * 40)
                    [void]$report.AppendLine("ADDED RULES (+)")
                    [void]$report.AppendLine("-" * 40)
                    foreach ($item in $diff.Added) {
                        [void]$report.AppendLine("  + $($item.Rule.Name)")
                        [void]$report.AppendLine("    Type: $($item.Rule.RuleType) | Action: $($item.Rule.Action)")
                    }
                    [void]$report.AppendLine("")
                }

                if ($diff.Removed.Count -gt 0) {
                    [void]$report.AppendLine("-" * 40)
                    [void]$report.AppendLine("REMOVED RULES (-)")
                    [void]$report.AppendLine("-" * 40)
                    foreach ($item in $diff.Removed) {
                        [void]$report.AppendLine("  - $($item.Rule.Name)")
                        [void]$report.AppendLine("    Type: $($item.Rule.RuleType) | Action: $($item.Rule.Action)")
                    }
                    [void]$report.AppendLine("")
                }

                if ($diff.Modified.Count -gt 0) {
                    [void]$report.AppendLine("-" * 40)
                    [void]$report.AppendLine("MODIFIED RULES (~)")
                    [void]$report.AppendLine("-" * 40)
                    foreach ($item in $diff.Modified) {
                        [void]$report.AppendLine("  ~ $($item.TargetRule.Name)")
                        foreach ($change in $item.Changes) {
                            [void]$report.AppendLine("    $($change.Property): '$($change.OldValue)' -> '$($change.NewValue)'")
                        }
                    }
                    [void]$report.AppendLine("")
                }

                [void]$report.AppendLine("=" * 60)
                [void]$report.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
            }
        }

        $result.Data = $report.ToString()
        $result.Success = $true
        Write-PolicyLog -Message "Generated $Format diff report for policies"
    }
    catch {
        $result.Error = "Failed to generate diff report: $($_.Exception.Message)"
        Write-PolicyLog -Level Error -Message $result.Error
    }

    return $result
}
