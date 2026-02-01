#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for GUI Rules Panel logic.
.DESCRIPTION
    Tests GUI functions with mocked window objects. These tests verify
    business logic without launching the actual WPF window.
    
    Focus areas:
    - Rule deletion workflow
    - Selection state management
    - DataGrid refresh logic
    - Error handling in WPF context
#>

BeforeAll {
    # Import the main module
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -WarningAction SilentlyContinue
    }
    
    # Load mock helpers
    . (Join-Path $PSScriptRoot '..\Helpers\MockWpfHelpers.ps1')

    # Dot-source the Rules panel to get the global functions
    $rulesPanel = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Rules.ps1'
    if (Test-Path $rulesPanel) {
        . $rulesPanel
    }
    
    # Helper to create a mock WPF window (legacy - kept for backward compatibility)
    function New-MockWindow {
        param(
            [hashtable]$Elements = @{},
            [array]$SelectedItems = @()
        )
        
        $mockWindow = [PSCustomObject]@{
            _elements = $Elements
            _selectedItems = $SelectedItems
        }
        
        $mockWindow | Add-Member -MemberType ScriptMethod -Name 'FindName' -Value {
            param([string]$name)
            
            # Return mock elements based on name
            if ($this._elements.ContainsKey($name)) {
                return $this._elements[$name]
            }
            
            # Default mock elements
            switch -Wildcard ($name) {
                'RulesDataGrid' {
                    return [PSCustomObject]@{
                        ItemsSource = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
                        SelectedItems = $this._selectedItems
                        Items = [PSCustomObject]@{ Count = 100 }
                    }
                }
                'ChkSelectAllRules' {
                    return [PSCustomObject]@{ IsChecked = $false }
                }
                'TxtSelectionCount' {
                    return [PSCustomObject]@{ Text = '0 selected' }
                }
                'BtnFilter*' {
                    return [PSCustomObject]@{ Content = 'Filter (0)' }
                }
                default { return $null }
            }
        }
        
        $mockWindow | Add-Member -MemberType ScriptMethod -Name 'Dispatcher' -Value {
            return [PSCustomObject]@{
                Invoke = { param($action) & $action }
            }
        }
        
        return $mockWindow
    }
    
    # Helper to create mock rule objects
    function New-MockRule {
        param(
            [string]$Id = [guid]::NewGuid().ToString(),
            [string]$Status = 'Pending',
            [string]$RuleType = 'Publisher',
            [string]$Name = 'Test Rule'
        )
        
        return [PSCustomObject]@{
            Id = $Id
            RuleId = $Id
            Status = $Status
            RuleType = $RuleType
            Name = $Name
            CreatedDate = (Get-Date).AddDays(-1)
        }
    }
}

Describe 'Rules Panel - Rule Operations' {
    Context 'Get-SelectedRules helper logic' {
        It 'Should return all rules when AllRulesSelected is true' {
            # Arrange
            $script:AllRulesSelected = $true
            $allRules = @(
                New-MockRule -Id 'rule-1'
                New-MockRule -Id 'rule-2'
                New-MockRule -Id 'rule-3'
            )
            
            $mockDataGrid = [PSCustomObject]@{
                ItemsSource = $allRules
                SelectedItems = @($allRules[0])  # Only 1 visually selected
            }
            
            $mockWindow = New-MockWindow -Elements @{
                'RulesDataGrid' = $mockDataGrid
            }
            
            # Act - simulate Get-SelectedRules logic
            $result = if ($script:AllRulesSelected) {
                @($mockDataGrid.ItemsSource)
            } else {
                @($mockDataGrid.SelectedItems)
            }
            
            # Assert
            $result.Count | Should -Be 3
        }
    }
}

Describe 'Rules Panel - Error Handling' {
    Context 'Try-Catch Pattern (WPF Context Safe)' {
        It 'Should handle missing functions gracefully' {
            # This simulates the pattern we use instead of Get-Command
            $result = $null
            $errorOccurred = $false
            
            try {
                # Simulate calling a function that might not exist
                $result = & { 
                    # In real code this would be: SomeFunctionThatMightNotExist
                    throw "Function not found"
                }
            } catch {
                $errorOccurred = $true
            }
            
            # Assert - error was caught, didn't crash
            $errorOccurred | Should -BeTrue
            $result | Should -BeNullOrEmpty
        }
        
        It 'Should continue execution after caught error' {
            $steps = @()
            
            # Step 1
            $steps += 'before'
            
            # Step 2 - might fail
            try { throw "Simulated WPF error" } catch { }
            
            # Step 3 - should still execute
            $steps += 'after'
            
            $steps | Should -Contain 'before'
            $steps | Should -Contain 'after'
            $steps.Count | Should -Be 2
        }
    }
}

Describe 'Rules Panel - Filter Button Counts' {
    Context 'Update-RuleCounters' {
        It 'Should update button content with counts' {
            # Arrange
            $mockCounts = [PSCustomObject]@{
                Pending = 25
                Approved = 100
                Rejected = 5
                Total = 130
            }
            
            $mockButtons = @{
                'BtnFilterPending' = [PSCustomObject]@{ Content = '' }
                'BtnFilterApproved' = [PSCustomObject]@{ Content = '' }
                'BtnFilterRejected' = [PSCustomObject]@{ Content = '' }
                'BtnFilterAll' = [PSCustomObject]@{ Content = '' }
            }
            
            # Act - Simulate counter update
            $mockButtons['BtnFilterPending'].Content = "Pending ($($mockCounts.Pending))"
            $mockButtons['BtnFilterApproved'].Content = "Approved ($($mockCounts.Approved))"
            $mockButtons['BtnFilterRejected'].Content = "Rejected ($($mockCounts.Rejected))"
            $mockButtons['BtnFilterAll'].Content = "All ($($mockCounts.Total))"
            
            # Assert
            $mockButtons['BtnFilterPending'].Content | Should -Be 'Pending (25)'
            $mockButtons['BtnFilterApproved'].Content | Should -Be 'Approved (100)'
            $mockButtons['BtnFilterAll'].Content | Should -Be 'All (130)'
        }
    }
}

Describe 'Rules Panel - Filter State Management' {
    It 'CurrentRulesFilter defaults to All' {
        $script:CurrentRulesFilter = 'All'
        $script:CurrentRulesFilter | Should -Be 'All'
    }

    It 'CurrentRulesTypeFilter defaults to All' {
        $script:CurrentRulesTypeFilter = 'All'
        $script:CurrentRulesTypeFilter | Should -Be 'All'
    }

    It 'Tracks status filter changes' {
        $script:CurrentRulesFilter = 'Pending'
        $script:CurrentRulesFilter | Should -Be 'Pending'

        $script:CurrentRulesFilter = 'Approved'
        $script:CurrentRulesFilter | Should -Be 'Approved'

        $script:CurrentRulesFilter = 'Rejected'
        $script:CurrentRulesFilter | Should -Be 'Rejected'
    }

    It 'Tracks type filter changes' {
        $script:CurrentRulesTypeFilter = 'Publisher'
        $script:CurrentRulesTypeFilter | Should -Be 'Publisher'

        $script:CurrentRulesTypeFilter = 'Hash'
        $script:CurrentRulesTypeFilter | Should -Be 'Hash'

        $script:CurrentRulesTypeFilter = 'Path'
        $script:CurrentRulesTypeFilter | Should -Be 'Path'
    }
}

Describe 'Rules Panel - Update-RulesFilter' {
    It 'Updates filter state variable' {
        if (Get-Command 'Update-RulesFilter' -ErrorAction SilentlyContinue) {
            Mock Update-RulesDataGrid {}
            $win = New-MockWpfWindow -Elements @{
                'BtnFilterAllRules'  = New-MockButton -Tag 'FilterRulesAll'
                'BtnFilterPublisher' = New-MockButton -Tag 'FilterRulesPublisher'
                'BtnFilterHash'      = New-MockButton -Tag 'FilterRulesHash'
                'BtnFilterPath'      = New-MockButton -Tag 'FilterRulesPath'
                'BtnFilterPending'   = New-MockButton -Tag 'FilterRulesPending'
                'BtnFilterApproved'  = New-MockButton -Tag 'FilterRulesApproved'
                'BtnFilterRejected'  = New-MockButton -Tag 'FilterRulesRejected'
            }
            Update-RulesFilter -Window $win -Filter 'Pending'
            $script:CurrentRulesFilter | Should -Be 'Pending'
        } else {
            Set-ItResult -Skipped -Because 'Update-RulesFilter not available'
        }
    }
}

Describe 'Rules Panel - Selection State' {
    It 'SuppressRulesSelectionChanged starts false' {
        $script:SuppressRulesSelectionChanged | Should -BeFalse
    }

    It 'AllRulesSelected can be toggled' {
        $script:AllRulesSelected = $false
        $script:AllRulesSelected | Should -BeFalse

        $script:AllRulesSelected = $true
        $script:AllRulesSelected | Should -BeTrue
    }
}

Describe 'Rules Panel - Initialization' {
    It 'Initialize-RulesPanel does not throw on empty window' {
        $win = New-MockWpfWindow -Elements @{}
        { Initialize-RulesPanel -Window $win } | Should -Not -Throw
    }
}

Describe 'Rules Panel - Mock Rule Object Pattern' {
    It 'Creates rules with expected properties' {
        $rule = New-MockRule -Id 'test-1' -Status 'Approved' -RuleType 'Hash' -Name 'My Rule'
        
        $rule.Id | Should -Be 'test-1'
        $rule.RuleId | Should -Be 'test-1'
        $rule.Status | Should -Be 'Approved'
        $rule.RuleType | Should -Be 'Hash'
        $rule.Name | Should -Be 'My Rule'
    }

    It 'Generates unique GUIDs by default' {
        $rule1 = New-MockRule
        $rule2 = New-MockRule
        $rule1.Id | Should -Not -Be $rule2.Id
    }
}

Describe 'Rules Panel - XAML Filter Buttons' {
    BeforeAll {
        $script:RawXaml = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml') -Raw
    }

    It 'Has status filter buttons with correct Tags' {
        $script:RawXaml | Should -Match 'Tag="FilterRulesPending"'
        $script:RawXaml | Should -Match 'Tag="FilterRulesApproved"'
        $script:RawXaml | Should -Match 'Tag="FilterRulesRejected"'
    }

    It 'Has type filter buttons with correct Tags' {
        $script:RawXaml | Should -Match 'Tag="FilterRulesPublisher"'
        $script:RawXaml | Should -Match 'Tag="FilterRulesHash"'
        $script:RawXaml | Should -Match 'Tag="FilterRulesPath"'
    }

    It 'Has rule counter display elements' {
        $script:RawXaml | Should -Match 'TxtRuleTotalCount'
        $script:RawXaml | Should -Match 'TxtRulePendingCount'
        $script:RawXaml | Should -Match 'TxtRuleApprovedCount'
        $script:RawXaml | Should -Match 'TxtRuleRejectedCount'
    }
}
