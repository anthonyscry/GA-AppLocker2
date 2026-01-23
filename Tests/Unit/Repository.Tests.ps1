#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Rule Repository pattern functions.

.DESCRIPTION
    Tests the repository abstraction layer over storage.

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Unit\Repository.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # Initialize database for tests
    Initialize-RuleDatabase -Force | Out-Null
}

AfterAll {
    # Cleanup test rules
    $testRules = Get-RulesFromDatabase | Where-Object { $_.Name -like 'TestRule*' }
    foreach ($rule in $testRules) {
        Remove-RuleFromDatabase -RuleId $rule.RuleId -ErrorAction SilentlyContinue | Out-Null
    }
}

Describe 'Rule Repository' -Tag 'Unit', 'Repository' {

    BeforeEach {
        # Clear cache before each test
        Clear-AppLockerCache | Out-Null
    }

    Context 'Get-RuleFromRepository' {

        It 'Returns null for non-existent rule' {
            $result = Get-RuleFromRepository -RuleId 'nonexistent-rule-id'
            
            $result | Should -BeNullOrEmpty
        }

        It 'Returns rule when it exists' {
            # Create a test rule first
            $testRule = @{
                RuleId = "test-repo-get-$(New-Guid)"
                Name = 'TestRuleRepoGet'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'A' * 64
                CreatedDate = (Get-Date).ToString('o')
            }
            Add-RuleToDatabase -Rule ([PSCustomObject]$testRule) | Out-Null

            $result = Get-RuleFromRepository -RuleId $testRule.RuleId

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestRuleRepoGet'

            # Cleanup
            Remove-RuleFromDatabase -RuleId $testRule.RuleId | Out-Null
        }

        It 'Uses cache for repeated requests' {
            $testRule = @{
                RuleId = "test-cache-$(New-Guid)"
                Name = 'TestRuleCaching'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'B' * 64
                CreatedDate = (Get-Date).ToString('o')
            }
            Add-RuleToDatabase -Rule ([PSCustomObject]$testRule) | Out-Null
            Clear-AppLockerCache | Out-Null
            Get-CacheStatistics -Reset | Out-Null

            # First request - cache miss
            Get-RuleFromRepository -RuleId $testRule.RuleId | Out-Null
            # Second request - should be cache hit
            Get-RuleFromRepository -RuleId $testRule.RuleId | Out-Null

            $stats = Get-CacheStatistics
            $stats.Hits | Should -BeGreaterOrEqual 1

            # Cleanup
            Remove-RuleFromDatabase -RuleId $testRule.RuleId | Out-Null
        }

        It 'BypassCache ignores cached value' {
            $testRule = @{
                RuleId = "test-bypass-$(New-Guid)"
                Name = 'TestRuleBypass'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'C' * 64
                CreatedDate = (Get-Date).ToString('o')
            }
            Add-RuleToDatabase -Rule ([PSCustomObject]$testRule) | Out-Null
            
            # Cache the original
            Get-RuleFromRepository -RuleId $testRule.RuleId | Out-Null
            
            # Update in database directly
            $testRule.Name = 'UpdatedName'
            Update-RuleInDatabase -RuleId $testRule.RuleId -UpdatedRule ([PSCustomObject]$testRule) | Out-Null

            # Without bypass - should return cached (old) value
            $cached = Get-RuleFromRepository -RuleId $testRule.RuleId
            # With bypass - should return new value
            $fresh = Get-RuleFromRepository -RuleId $testRule.RuleId -BypassCache

            $fresh.Name | Should -Be 'UpdatedName'

            # Cleanup
            Remove-RuleFromDatabase -RuleId $testRule.RuleId | Out-Null
        }
    }

    Context 'Save-RuleToRepository' {

        It 'Creates new rule successfully' {
            $newRule = [PSCustomObject]@{
                RuleId = "test-save-new-$(New-Guid)"
                Name = 'TestRuleSaveNew'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'D' * 64
                CreatedDate = (Get-Date).ToString('o')
            }

            $result = Save-RuleToRepository -Rule $newRule -IsNew

            $result.Success | Should -BeTrue
            
            # Verify it was saved
            $saved = Get-RuleFromDatabase -RuleId $newRule.RuleId
            $saved | Should -Not -BeNullOrEmpty

            # Cleanup
            Remove-RuleFromDatabase -RuleId $newRule.RuleId | Out-Null
        }

        It 'Updates existing rule' {
            $rule = [PSCustomObject]@{
                RuleId = "test-save-update-$(New-Guid)"
                Name = 'TestRuleOriginal'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'E' * 64
                CreatedDate = (Get-Date).ToString('o')
            }
            Add-RuleToDatabase -Rule $rule | Out-Null

            $rule.Name = 'TestRuleUpdated'
            $rule.Status = 'Approved'
            $result = Save-RuleToRepository -Rule $rule

            $result.Success | Should -BeTrue
            
            $updated = Get-RuleFromDatabase -RuleId $rule.RuleId
            $updated.Name | Should -Be 'TestRuleUpdated'
            $updated.Status | Should -Be 'Approved'

            # Cleanup
            Remove-RuleFromDatabase -RuleId $rule.RuleId | Out-Null
        }

        It 'Invalidates cache on save' {
            $rule = [PSCustomObject]@{
                RuleId = "test-cache-invalidate-$(New-Guid)"
                Name = 'TestRuleCacheInv'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'F' * 64
                CreatedDate = (Get-Date).ToString('o')
            }
            Save-RuleToRepository -Rule $rule -IsNew | Out-Null
            
            # Cache it
            Get-RuleFromRepository -RuleId $rule.RuleId | Out-Null
            
            # Update
            $rule.Status = 'Approved'
            Save-RuleToRepository -Rule $rule | Out-Null

            # Cache should be invalidated, get fresh
            $result = Get-RuleFromRepository -RuleId $rule.RuleId
            $result.Status | Should -Be 'Approved'

            # Cleanup
            Remove-RuleFromDatabase -RuleId $rule.RuleId | Out-Null
        }

        It 'Returns error for rule without RuleId' {
            $invalidRule = [PSCustomObject]@{
                Name = 'NoId'
            }

            $result = Save-RuleToRepository -Rule $invalidRule

            $result.Success | Should -BeFalse
            $result.Error | Should -Match 'RuleId'
        }
    }

    Context 'Remove-RuleFromRepository' {

        It 'Removes existing rule' {
            $rule = [PSCustomObject]@{
                RuleId = "test-remove-$(New-Guid)"
                Name = 'TestRuleRemove'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'G' * 64
                CreatedDate = (Get-Date).ToString('o')
            }
            Add-RuleToDatabase -Rule $rule | Out-Null

            $result = Remove-RuleFromRepository -RuleId $rule.RuleId

            $result.Success | Should -BeTrue
            
            $deleted = Get-RuleFromDatabase -RuleId $rule.RuleId
            $deleted | Should -BeNullOrEmpty
        }

        It 'Invalidates cache on delete' {
            $rule = [PSCustomObject]@{
                RuleId = "test-remove-cache-$(New-Guid)"
                Name = 'TestRuleRemoveCache'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'H' * 64
                CreatedDate = (Get-Date).ToString('o')
            }
            Add-RuleToDatabase -Rule $rule | Out-Null
            Get-RuleFromRepository -RuleId $rule.RuleId | Out-Null  # Cache it

            Remove-RuleFromRepository -RuleId $rule.RuleId | Out-Null

            $result = Get-RuleFromRepository -RuleId $rule.RuleId
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Find-RulesInRepository' {

        BeforeAll {
            # Create test rules for filtering
            $script:TestRuleIds = @()
            $statuses = @('Pending', 'Approved', 'Rejected')
            foreach ($status in $statuses) {
                $rule = [PSCustomObject]@{
                    RuleId = "test-find-$status-$(New-Guid)"
                    Name = "TestRuleFind$status"
                    RuleType = 'Hash'
                    Status = $status
                    CollectionType = 'Exe'
                    Action = 'Allow'
                    Hash = "$(Get-Random)" + ('0' * 55)
                    CreatedDate = (Get-Date).ToString('o')
                }
                Add-RuleToDatabase -Rule $rule | Out-Null
                $script:TestRuleIds += $rule.RuleId
            }
        }

        AfterAll {
            foreach ($id in $script:TestRuleIds) {
                Remove-RuleFromDatabase -RuleId $id -ErrorAction SilentlyContinue | Out-Null
            }
        }

        It 'Filters by status' {
            $results = Find-RulesInRepository -Filter @{ Status = 'Pending' } -BypassCache

            $results | Should -Not -BeNullOrEmpty
            $results | ForEach-Object { $_.Status | Should -Be 'Pending' }
        }

        It 'Returns empty for no matches' {
            $results = Find-RulesInRepository -Filter @{ Status = 'NonExistentStatus' }

            $results.Count | Should -Be 0
        }

        It 'Respects Take parameter' {
            $results = Find-RulesInRepository -Take 2 -BypassCache

            $results.Count | Should -BeLessOrEqual 2
        }
    }

    Context 'Get-RuleCountsFromRepository' {

        It 'Returns counts object' {
            $counts = Get-RuleCountsFromRepository -BypassCache

            $counts | Should -Not -BeNullOrEmpty
            $counts.PSObject.Properties.Name | Should -Contain 'Total'
        }

        It 'Uses cache for repeated requests' {
            Get-CacheStatistics -Reset | Out-Null
            
            Get-RuleCountsFromRepository | Out-Null
            Get-RuleCountsFromRepository | Out-Null

            $stats = Get-CacheStatistics
            $stats.Hits | Should -BeGreaterOrEqual 1
        }
    }

    Context 'Test-RuleExistsInRepository' {

        It 'Returns true for existing rule' {
            $rule = [PSCustomObject]@{
                RuleId = "test-exists-$(New-Guid)"
                Name = 'TestRuleExists'
                RuleType = 'Hash'
                Status = 'Pending'
                CollectionType = 'Exe'
                Action = 'Allow'
                Hash = 'I' * 64
                CreatedDate = (Get-Date).ToString('o')
            }
            Add-RuleToDatabase -Rule $rule | Out-Null

            $result = Test-RuleExistsInRepository -RuleId $rule.RuleId

            $result | Should -BeTrue

            # Cleanup
            Remove-RuleFromDatabase -RuleId $rule.RuleId | Out-Null
        }

        It 'Returns false for non-existent rule' {
            $result = Test-RuleExistsInRepository -RuleId 'nonexistent-rule-xyz'

            $result | Should -BeFalse
        }
    }

    Context 'Invoke-RuleBatchOperation' {

        It 'Updates status for multiple rules' {
            $ruleIds = @()
            1..3 | ForEach-Object {
                $rule = [PSCustomObject]@{
                    RuleId = "test-batch-$_-$(New-Guid)"
                    Name = "TestRuleBatch$_"
                    RuleType = 'Hash'
                    Status = 'Pending'
                    CollectionType = 'Exe'
                    Action = 'Allow'
                    Hash = "$_" + ('0' * 63)
                    CreatedDate = (Get-Date).ToString('o')
                }
                Add-RuleToDatabase -Rule $rule | Out-Null
                $ruleIds += $rule.RuleId
            }

            $result = Invoke-RuleBatchOperation -RuleIds $ruleIds -Operation 'UpdateStatus' -Parameters @{ Status = 'Approved' }

            $result.Processed | Should -Be 3
            $result.Failed | Should -Be 0

            # Verify updates
            foreach ($id in $ruleIds) {
                $rule = Get-RuleFromDatabase -RuleId $id
                $rule.Status | Should -Be 'Approved'
                Remove-RuleFromDatabase -RuleId $id | Out-Null
            }
        }

        It 'Deletes multiple rules' {
            $ruleIds = @()
            1..2 | ForEach-Object {
                $rule = [PSCustomObject]@{
                    RuleId = "test-batch-del-$_-$(New-Guid)"
                    Name = "TestRuleBatchDel$_"
                    RuleType = 'Hash'
                    Status = 'Pending'
                    CollectionType = 'Exe'
                    Action = 'Allow'
                    Hash = "$_" + ('1' * 63)
                    CreatedDate = (Get-Date).ToString('o')
                }
                Add-RuleToDatabase -Rule $rule | Out-Null
                $ruleIds += $rule.RuleId
            }

            $result = Invoke-RuleBatchOperation -RuleIds $ruleIds -Operation 'Delete'

            $result.Processed | Should -Be 2

            # Verify deletions
            foreach ($id in $ruleIds) {
                $rule = Get-RuleFromDatabase -RuleId $id
                $rule | Should -BeNullOrEmpty
            }
        }
    }
}
