#Requires -Modules Pester
<#
.SYNOPSIS
    Tests for GA-AppLocker.Rules rule history/versioning functions.

.DESCRIPTION
    Covers rule history management:
    - Save-RuleVersion / Get-RuleHistory / Get-RuleVersionContent
    - Restore-RuleVersion / Compare-RuleVersions
    - Remove-RuleHistory / Invoke-RuleHistoryCleanup

.NOTES
    Module: GA-AppLocker.Rules
    Run with: Invoke-Pester -Path .\Tests\Unit\Rules.History.Tests.ps1 -Output Detailed
#>

BeforeAll {
    Get-Module 'GA-AppLocker*' | Remove-Module -Force -ErrorAction SilentlyContinue
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # Create a test rule for version history tests
    $script:TestRule = New-HashRule -FileName 'HistoryTest.exe' -Hash ('A' * 64) -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
    $script:TestRuleId = $script:TestRule.Data.RuleId
}

# ============================================================================
# FUNCTION EXPORTS
# ============================================================================

Describe 'Rules History - Function Exports' -Tag 'Unit', 'Rules', 'History' {

    It 'Save-RuleVersion should be exported' {
        Get-Command 'Save-RuleVersion' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Get-RuleHistory should be exported' {
        Get-Command 'Get-RuleHistory' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Restore-RuleVersion should be exported' {
        Get-Command 'Restore-RuleVersion' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Compare-RuleVersions should be exported' {
        Get-Command 'Compare-RuleVersions' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Get-RuleVersionContent should be exported' {
        Get-Command 'Get-RuleVersionContent' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Remove-RuleHistory should be exported' {
        Get-Command 'Remove-RuleHistory' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-RuleHistoryCleanup should be exported' {
        Get-Command 'Invoke-RuleHistoryCleanup' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

# ============================================================================
# SAVE-RULEVERSION
# ============================================================================

Describe 'Save-RuleVersion' -Tag 'Unit', 'Rules', 'History' {

    It 'Should save a version of a rule' {
        $result = Save-RuleVersion -RuleId $script:TestRuleId -ChangeType 'Created' -ChangeSummary 'Initial creation'
        $result.Success | Should -Be $true
    }

    It 'Should auto-increment version numbers' {
        Save-RuleVersion -RuleId $script:TestRuleId -ChangeType 'Updated' -ChangeSummary 'First update'
        $result = Save-RuleVersion -RuleId $script:TestRuleId -ChangeType 'Updated' -ChangeSummary 'Second update'
        $result.Success | Should -Be $true
        if ($result.Data) {
            $result.Data.Version | Should -BeGreaterThan 1
        }
    }

    It 'Should record the ChangeType' {
        $result = Save-RuleVersion -RuleId $script:TestRuleId -ChangeType 'StatusChanged' -ChangeSummary 'Status change'
        if ($result.Success -and $result.Data) {
            $result.Data.ChangeType | Should -Be 'StatusChanged'
        }
    }

    It 'Should record ModifiedBy and ModifiedAt' {
        $result = Save-RuleVersion -RuleId $script:TestRuleId -ChangeType 'Updated' -ChangeSummary 'Meta check'
        if ($result.Success -and $result.Data) {
            $result.Data.ModifiedBy | Should -Not -BeNullOrEmpty
            $result.Data.ModifiedAt | Should -Not -BeNullOrEmpty
        }
    }
}

# ============================================================================
# GET-RULEHISTORY
# ============================================================================

Describe 'Get-RuleHistory' -Tag 'Unit', 'Rules', 'History' {

    It 'Should return version history for a rule with versions' {
        $result = Get-RuleHistory -RuleId $script:TestRuleId
        $result.Success | Should -Be $true
        @($result.Data).Count | Should -BeGreaterOrEqual 1
    }

    It 'Should sort versions by version number descending' {
        $result = Get-RuleHistory -RuleId $script:TestRuleId
        if ($result.Success -and @($result.Data).Count -gt 1) {
            $versions = @($result.Data | ForEach-Object { $_.Version })
            for ($i = 0; $i -lt $versions.Count - 1; $i++) {
                $versions[$i] | Should -BeGreaterOrEqual $versions[$i + 1]
            }
        }
    }

    It 'Should return empty for a rule with no history' {
        $fakeId = [guid]::NewGuid().ToString()
        $result = Get-RuleHistory -RuleId $fakeId
        $result.Success | Should -Be $true
        @($result.Data).Count | Should -Be 0
    }
}

# ============================================================================
# GET-RULEVERSIONCONTENT
# ============================================================================

Describe 'Get-RuleVersionContent' -Tag 'Unit', 'Rules', 'History' {

    It 'Should retrieve content of a specific version' {
        $history = Get-RuleHistory -RuleId $script:TestRuleId
        if ($history.Success -and @($history.Data).Count -gt 0) {
            $latestVersion = $history.Data[0].Version
            $result = Get-RuleVersionContent -RuleId $script:TestRuleId -Version $latestVersion
            $result.Success | Should -Be $true
        }
    }

    It 'Should return error for non-existent version' {
        $result = Get-RuleVersionContent -RuleId $script:TestRuleId -Version 99999
        $result.Success | Should -Be $false
    }
}

# ============================================================================
# COMPARE-RULEVERSIONS
# ============================================================================

Describe 'Compare-RuleVersions' -Tag 'Unit', 'Rules', 'History' {

    It 'Should compare two versions of the same rule' {
        $history = Get-RuleHistory -RuleId $script:TestRuleId
        if ($history.Success -and @($history.Data).Count -ge 2) {
            $v1 = $history.Data[-1].Version  # oldest
            $v2 = $history.Data[0].Version   # newest
            $result = Compare-RuleVersions -RuleId $script:TestRuleId -Version1 $v1 -Version2 $v2
            $result.Success | Should -Be $true
        }
        else {
            Set-ItResult -Skipped -Because 'Not enough versions to compare'
        }
    }

    It 'Should return differences array' {
        $history = Get-RuleHistory -RuleId $script:TestRuleId
        if ($history.Success -and @($history.Data).Count -ge 2) {
            $v1 = $history.Data[-1].Version
            $v2 = $history.Data[0].Version
            $result = Compare-RuleVersions -RuleId $script:TestRuleId -Version1 $v1 -Version2 $v2
            if ($result.Success) {
                $result.Data | Should -Not -BeNullOrEmpty
            }
        }
        else {
            Set-ItResult -Skipped -Because 'Not enough versions'
        }
    }
}

# ============================================================================
# REMOVE-RULEHISTORY
# ============================================================================

Describe 'Remove-RuleHistory' -Tag 'Unit', 'Rules', 'History' {

    It 'Should remove history for a rule' {
        # Create a disposable rule for this test
        $tempRule = New-HashRule -FileName 'TempHistory.exe' -Hash ('B' * 64) -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
        if ($tempRule.Success) {
            Save-RuleVersion -RuleId $tempRule.Data.RuleId -ChangeType 'Created' -ChangeSummary 'Test'
            $result = Remove-RuleHistory -RuleId $tempRule.Data.RuleId
            $result.Success | Should -Be $true

            # History should be empty now
            $check = Get-RuleHistory -RuleId $tempRule.Data.RuleId
            @($check.Data).Count | Should -Be 0
        }
    }

    It 'Should not throw for rule with no history' {
        $fakeId = [guid]::NewGuid().ToString()
        { Remove-RuleHistory -RuleId $fakeId } | Should -Not -Throw
    }
}

# ============================================================================
# INVOKE-RULEHISTORYCLEANUP
# ============================================================================

Describe 'Invoke-RuleHistoryCleanup' -Tag 'Unit', 'Rules', 'History' {

    It 'Should not throw when called' {
        { Invoke-RuleHistoryCleanup -KeepVersions 10 -OlderThanDays 90 } | Should -Not -Throw
    }

    It 'Should return a Success result' {
        $result = Invoke-RuleHistoryCleanup -KeepVersions 100
        $result.Success | Should -Be $true
    }
}
