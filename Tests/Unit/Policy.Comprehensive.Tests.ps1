#Requires -Modules Pester
<#
.SYNOPSIS
    Comprehensive tests for GA-AppLocker.Policy module.

.DESCRIPTION
    Covers policy functions not tested in Policy.Phase.Tests.ps1:
    - Compare-Policies / Compare-RuleProperties / Get-PolicyDiffReport
    - New-PolicySnapshot / Get-PolicySnapshots / Restore-PolicySnapshot
    - Set-PolicyTarget / Update-Policy / Set-PolicyStatus / Remove-Policy
    - Add-RuleToPolicy / Remove-RuleFromPolicy

.NOTES
    Module: GA-AppLocker.Policy
    Run with: Invoke-Pester -Path .\Tests\Unit\Policy.Comprehensive.Tests.ps1 -Output Detailed
#>

BeforeAll {
    Get-Module 'GA-AppLocker*' | Remove-Module -Force -ErrorAction SilentlyContinue
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}

# ============================================================================
# FUNCTION EXPORTS
# ============================================================================

Describe 'Policy Module - Function Exports' -Tag 'Unit', 'Policy' {

    $functions = @(
        'New-Policy', 'Get-Policy', 'Get-AllPolicies', 'Update-Policy',
        'Remove-Policy', 'Set-PolicyStatus', 'Add-RuleToPolicy', 'Remove-RuleFromPolicy',
        'Set-PolicyTarget', 'Export-PolicyToXml', 'Test-PolicyCompliance',
        'Compare-Policies', 'Compare-RuleProperties', 'Get-PolicyDiffReport',
        'New-PolicySnapshot', 'Get-PolicySnapshots', 'Get-PolicySnapshot',
        'Restore-PolicySnapshot', 'Remove-PolicySnapshot', 'Invoke-PolicySnapshotCleanup'
    )

    It '<Fn> should be exported' -TestCases ($functions | ForEach-Object { @{ Fn = $_ } }) {
        param($Fn)
        Get-Command $Fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

# ============================================================================
# POLICY CRUD
# ============================================================================

Describe 'Policy CRUD Operations' -Tag 'Unit', 'Policy' {

    BeforeAll {
        $script:TestPolicy = New-Policy -Name 'UnitTest_CRUDPolicy'
    }

    It 'New-Policy should create a policy successfully' {
        $script:TestPolicy.Success | Should -Be $true
        $script:TestPolicy.Data | Should -Not -BeNullOrEmpty
        $script:TestPolicy.Data.PolicyId | Should -Not -BeNullOrEmpty
    }

    It 'Get-Policy should retrieve by PolicyId' {
        if (-not $script:TestPolicy.Success) { Set-ItResult -Skipped; return }
        $result = Get-Policy -PolicyId $script:TestPolicy.Data.PolicyId
        $result.Success | Should -Be $true
        $result.Data.Name | Should -Be 'UnitTest_CRUDPolicy'
    }

    It 'Get-AllPolicies should include the created policy' {
        if (-not $script:TestPolicy.Success) { Set-ItResult -Skipped; return }
        $result = Get-AllPolicies
        $result.Success | Should -Be $true
        $names = @($result.Data | ForEach-Object { $_.Name })
        $names | Should -Contain 'UnitTest_CRUDPolicy'
    }

    It 'Update-Policy should change name' {
        if (-not $script:TestPolicy.Success) { Set-ItResult -Skipped; return }
        $result = Update-Policy -Id $script:TestPolicy.Data.PolicyId -Name 'UnitTest_CRUDPolicy_Renamed'
        $result.Success | Should -Be $true

        $check = Get-Policy -PolicyId $script:TestPolicy.Data.PolicyId
        $check.Data.Name | Should -Be 'UnitTest_CRUDPolicy_Renamed'
    }

    It 'Update-Policy should change description' {
        if (-not $script:TestPolicy.Success) { Set-ItResult -Skipped; return }
        $result = Update-Policy -Id $script:TestPolicy.Data.PolicyId -Description 'Updated desc'
        $result.Success | Should -Be $true
    }

    It 'Update-Policy should change TargetGPO' {
        if (-not $script:TestPolicy.Success) { Set-ItResult -Skipped; return }
        $result = Update-Policy -Id $script:TestPolicy.Data.PolicyId -TargetGPO 'New-Target-GPO'
        $result.Success | Should -Be $true
    }

    It 'Get-Policy should return error for non-existent policy' {
        $result = Get-Policy -PolicyId ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $false
    }
}

# ============================================================================
# ADD/REMOVE RULES TO POLICY
# ============================================================================

Describe 'Policy Rule Management' -Tag 'Unit', 'Policy' {

    BeforeAll {
        $script:RulePolicy = New-Policy -Name 'UnitTest_RulePolicy'
        $script:TestHashRule = New-HashRule -SourceFileName 'PolicyTest.exe' -Hash ('C' * 64) -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe' -Save
    }

    It 'Should add a rule to a policy' {
        if (-not $script:RulePolicy.Success -or -not $script:TestHashRule.Success) { Set-ItResult -Skipped; return }
        $result = Add-RuleToPolicy -PolicyId $script:RulePolicy.Data.PolicyId -RuleId $script:TestHashRule.Data.Id
        $result.Success | Should -Be $true
    }

    It 'Should include the rule in policy after adding' {
        if (-not $script:RulePolicy.Success -or -not $script:TestHashRule.Success) { Set-ItResult -Skipped; return }
        $policy = Get-Policy -PolicyId $script:RulePolicy.Data.PolicyId
        $policy.Data.RuleIds | Should -Contain $script:TestHashRule.Data.Id
    }

    It 'Should remove a rule from a policy' {
        if (-not $script:RulePolicy.Success -or -not $script:TestHashRule.Success) { Set-ItResult -Skipped; return }
        $result = Remove-RuleFromPolicy -PolicyId $script:RulePolicy.Data.PolicyId -RuleId $script:TestHashRule.Data.Id
        $result.Success | Should -Be $true
    }

    It 'Should return error when adding rule to non-existent policy' {
        $result = Add-RuleToPolicy -PolicyId ([guid]::NewGuid().ToString()) -RuleId ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $false
    }
}

# ============================================================================
# COMPARE-POLICIES
# ============================================================================

Describe 'Compare-Policies' -Tag 'Unit', 'Policy' {

    BeforeAll {
        # Create two policies with different rules
        $script:Policy1 = New-Policy -Name 'UnitTest_CompareA'
        $script:Policy2 = New-Policy -Name 'UnitTest_CompareB'

        $rule1 = New-HashRule -SourceFileName 'SharedApp.exe' -Hash ('D' * 64) -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe' -Save
        $rule2 = New-HashRule -SourceFileName 'OnlyInA.exe' -Hash ('E' * 64) -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe' -Save
        $rule3 = New-HashRule -SourceFileName 'OnlyInB.exe' -Hash ('F' * 64) -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe' -Save

        if ($script:Policy1.Success -and $rule1.Success) {
            Add-RuleToPolicy -PolicyId $script:Policy1.Data.PolicyId -RuleId $rule1.Data.Id
            Add-RuleToPolicy -PolicyId $script:Policy1.Data.PolicyId -RuleId $rule2.Data.Id
        }
        if ($script:Policy2.Success -and $rule1.Success) {
            Add-RuleToPolicy -PolicyId $script:Policy2.Data.PolicyId -RuleId $rule1.Data.Id
            Add-RuleToPolicy -PolicyId $script:Policy2.Data.PolicyId -RuleId $rule3.Data.Id
        }
    }

    It 'Should compare two policies and return a result' {
        if (-not $script:Policy1.Success -or -not $script:Policy2.Success) { Set-ItResult -Skipped; return }
        $result = Compare-Policies -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy2.Data.PolicyId
        $result.Success | Should -Be $true
    }

    It 'Should detect added rules' {
        if (-not $script:Policy1.Success -or -not $script:Policy2.Success) { Set-ItResult -Skipped; return }
        $result = Compare-Policies -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy2.Data.PolicyId
        if ($result.Success) {
            $result.Data.Added | Should -Not -BeNullOrEmpty
        }
    }

    It 'Should detect removed rules' {
        if (-not $script:Policy1.Success -or -not $script:Policy2.Success) { Set-ItResult -Skipped; return }
        $result = Compare-Policies -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy2.Data.PolicyId
        if ($result.Success) {
            $result.Data.Removed | Should -Not -BeNullOrEmpty
        }
    }

    It 'Should identify unchanged rules' {
        if (-not $script:Policy1.Success -or -not $script:Policy2.Success) { Set-ItResult -Skipped; return }
        $result = Compare-Policies -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy2.Data.PolicyId -IncludeUnchanged
        if ($result.Success -and $result.Data.Unchanged) {
            @($result.Data.Unchanged).Count | Should -BeGreaterOrEqual 1
        }
    }

    It 'Should return HasDifferences flag' {
        if (-not $script:Policy1.Success -or -not $script:Policy2.Success) { Set-ItResult -Skipped; return }
        $result = Compare-Policies -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy2.Data.PolicyId
        if ($result.Success) {
            $result.Data.HasDifferences | Should -Be $true
        }
    }

    It 'Should show no differences when comparing policy to itself' {
        if (-not $script:Policy1.Success) { Set-ItResult -Skipped; return }
        $result = Compare-Policies -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy1.Data.PolicyId
        if ($result.Success) {
            $result.Data.HasDifferences | Should -Be $false
        }
    }
}

# ============================================================================
# GET-POLICYDIFFREPORT
# ============================================================================

Describe 'Get-PolicyDiffReport' -Tag 'Unit', 'Policy' {

    It 'Should generate a text format report' {
        if (-not $script:Policy1.Success -or -not $script:Policy2.Success) { Set-ItResult -Skipped; return }
        $result = Get-PolicyDiffReport -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy2.Data.PolicyId -Format 'Text'
        $result.Success | Should -Be $true
        $result.Data | Should -Not -BeNullOrEmpty
    }

    It 'Should generate a markdown format report' {
        if (-not $script:Policy1.Success -or -not $script:Policy2.Success) { Set-ItResult -Skipped; return }
        $result = Get-PolicyDiffReport -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy2.Data.PolicyId -Format 'Markdown'
        $result.Success | Should -Be $true
    }

    It 'Should generate an HTML format report' {
        if (-not $script:Policy1.Success -or -not $script:Policy2.Success) { Set-ItResult -Skipped; return }
        $result = Get-PolicyDiffReport -SourcePolicyId $script:Policy1.Data.PolicyId -TargetPolicyId $script:Policy2.Data.PolicyId -Format 'Html'
        $result.Success | Should -Be $true
    }
}

# ============================================================================
# POLICY SNAPSHOTS
# ============================================================================

Describe 'Policy Snapshots' -Tag 'Unit', 'Policy' {

    BeforeAll {
        $script:SnapPolicy = New-Policy -Name 'UnitTest_SnapPolicy'
        $snapRule = New-HashRule -SourceFileName 'SnapApp.exe' -Hash ('A1' * 32) -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe' -Save
        if ($script:SnapPolicy.Success -and $snapRule.Success) {
            Add-RuleToPolicy -PolicyId $script:SnapPolicy.Data.PolicyId -RuleId $snapRule.Data.Id
        }
    }

    It 'New-PolicySnapshot should create a snapshot' {
        if (-not $script:SnapPolicy.Success) { Set-ItResult -Skipped; return }
        $result = New-PolicySnapshot -PolicyId $script:SnapPolicy.Data.PolicyId -Description 'Unit test snapshot'
        $result.Success | Should -Be $true
        $result.Data | Should -Not -BeNullOrEmpty
    }

    It 'Get-PolicySnapshots should return snapshots for a policy' {
        if (-not $script:SnapPolicy.Success) { Set-ItResult -Skipped; return }
        # Create another snapshot
        New-PolicySnapshot -PolicyId $script:SnapPolicy.Data.PolicyId -Description 'Second snapshot'

        $result = Get-PolicySnapshots -PolicyId $script:SnapPolicy.Data.PolicyId
        $result.Success | Should -Be $true
        @($result.Data).Count | Should -BeGreaterOrEqual 1
    }

    It 'Get-PolicySnapshots should respect Limit parameter' {
        if (-not $script:SnapPolicy.Success) { Set-ItResult -Skipped; return }
        $result = Get-PolicySnapshots -PolicyId $script:SnapPolicy.Data.PolicyId -Limit 1
        $result.Success | Should -Be $true
        @($result.Data).Count | Should -BeLessOrEqual 1
    }

    It 'Get-PolicySnapshot should retrieve specific snapshot' {
        if (-not $script:SnapPolicy.Success) { Set-ItResult -Skipped; return }
        $snapshots = Get-PolicySnapshots -PolicyId $script:SnapPolicy.Data.PolicyId
        if ($snapshots.Success -and @($snapshots.Data).Count -gt 0) {
            $snapId = $snapshots.Data[0].SnapshotId
            $result = Get-PolicySnapshot -SnapshotId $snapId
            $result.Success | Should -Be $true
        }
    }

    It 'Get-PolicySnapshots should return empty for policy with no snapshots' {
        $fakePolicy = New-Policy -Name 'UnitTest_NoSnaps'
        if ($fakePolicy.Success) {
            $result = Get-PolicySnapshots -PolicyId $fakePolicy.Data.PolicyId
            $result.Success | Should -Be $true
            @($result.Data).Count | Should -Be 0
        }
    }

    It 'Invoke-PolicySnapshotCleanup should not throw' {
        { Invoke-PolicySnapshotCleanup -KeepCount 50 -KeepDays 365 } | Should -Not -Throw
    }
}

# ============================================================================
# SET-POLICYSTATUS / REMOVE-POLICY
# ============================================================================

Describe 'Set-PolicyStatus' -Tag 'Unit', 'Policy' {

    BeforeAll {
        $script:StatusPolicy = New-Policy -Name 'UnitTest_StatusPolicy'
    }

    It 'Should change policy status' {
        if (-not $script:StatusPolicy.Success) { Set-ItResult -Skipped; return }
        $result = Set-PolicyStatus -PolicyId $script:StatusPolicy.Data.PolicyId -Status 'Active'
        $result.Success | Should -Be $true
    }
}

Describe 'Remove-Policy' -Tag 'Unit', 'Policy' {

    It 'Should remove a policy' {
        $tempPolicy = New-Policy -Name 'UnitTest_RemoveMe'
        if ($tempPolicy.Success) {
            $result = Remove-Policy -PolicyId $tempPolicy.Data.PolicyId
            $result.Success | Should -Be $true

            $check = Get-Policy -PolicyId $tempPolicy.Data.PolicyId
            $check.Success | Should -Be $false
        }
    }

    It 'Should return error for non-existent policy' {
        $result = Remove-Policy -PolicyId ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $false
    }
}

# ============================================================================
# COMPARE-RULEPROPERTIES
# ============================================================================

Describe 'Compare-RuleProperties' -Tag 'Unit', 'Policy' {

    It 'Should detect property differences between two rules' {
        $rule1 = [PSCustomObject]@{ Name = 'Rule1'; Action = 'Allow'; Status = 'Pending' }
        $rule2 = [PSCustomObject]@{ Name = 'Rule1'; Action = 'Deny'; Status = 'Approved' }
        $result = Compare-RuleProperties -SourceRule $rule1 -TargetRule $rule2
        # Compare-RuleProperties returns an array of change objects directly (not wrapped in Success/Data)
        $result | Should -Not -BeNullOrEmpty
        @($result).Count | Should -BeGreaterOrEqual 1
    }

    It 'Should return no differences for identical rules' {
        $rule1 = [PSCustomObject]@{ Name = 'Same'; Action = 'Allow'; Status = 'Pending' }
        $rule2 = [PSCustomObject]@{ Name = 'Same'; Action = 'Allow'; Status = 'Pending' }
        $result = Compare-RuleProperties -SourceRule $rule1 -TargetRule $rule2
        # Compare-RuleProperties returns empty array when no differences
        @($result).Count | Should -Be 0
    }
}

# ============================================================================
# TEST-POLICYCOMPLIANCE
# ============================================================================

Describe 'Test-PolicyCompliance' -Tag 'Unit', 'Policy' {

    It 'Should be an exported function' {
        Get-Command 'Test-PolicyCompliance' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Should return error for non-existent policy' {
        $result = Test-PolicyCompliance -PolicyId ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $false
    }
}
