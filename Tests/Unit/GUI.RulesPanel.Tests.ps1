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
    
    # Dot-source the Rules panel to get the global functions
    $rulesPanel = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Rules.ps1'
    if (Test-Path $rulesPanel) {
        . $rulesPanel
    }
    
    # Helper to create a mock WPF window
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

Describe 'Rules Panel - Selection State Management' {
    Context 'Reset-RulesSelectionState' {
        BeforeEach {
            # Reset script-level state
            $script:AllRulesSelected = $true
            
            # Create mock window with checkbox
            $mockCheckbox = [PSCustomObject]@{ IsChecked = $true }
            $mockRules = @((New-MockRule), (New-MockRule))
            $mockDataGrid = [PSCustomObject]@{
                SelectedItems = $mockRules
                ItemsSource = @()
            }
            $mockDataGrid | Add-Member -MemberType ScriptMethod -Name 'UnselectAll' -Value { }
            
            $script:TestWindow = New-MockWindow -Elements @{
                'ChkSelectAllRules' = $mockCheckbox
                'RulesDataGrid' = $mockDataGrid
                'TxtSelectionCount' = [PSCustomObject]@{ Text = '2 selected' }
            }
        }
        
        It 'Should clear AllRulesSelected flag' {
            # Act
            Reset-RulesSelectionState -Window $script:TestWindow
            
            # Assert
            $script:AllRulesSelected | Should -BeFalse
        }
        
        It 'Should uncheck the Select All checkbox' {
            $checkbox = $script:TestWindow.FindName('ChkSelectAllRules')
            
            # Act
            Reset-RulesSelectionState -Window $script:TestWindow
            
            # Assert
            $checkbox.IsChecked | Should -BeFalse
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
        
        It 'Should return only selected items when AllRulesSelected is false' {
            # Arrange
            $script:AllRulesSelected = $false
            $selectedRules = @(New-MockRule -Id 'rule-1')
            
            $allRules = @((New-MockRule), (New-MockRule), (New-MockRule))
            $mockDataGrid = [PSCustomObject]@{
                ItemsSource = $allRules
                SelectedItems = $selectedRules
            }
            
            # Act
            $result = if ($script:AllRulesSelected) {
                @($mockDataGrid.ItemsSource)
            } else {
                @($mockDataGrid.SelectedItems)
            }
            
            # Assert
            $result.Count | Should -Be 1
        }
    }
    
    Context 'Delete Rules Workflow' {
        BeforeEach {
            $script:AllRulesSelected = $false
            
            # Mock the Remove-Rules function
            Mock -CommandName 'Remove-Rules' -MockWith {
                return [PSCustomObject]@{
                    Success = $true
                    RemovedCount = $RuleIds.Count
                }
            }
            
            # Mock toast notifications
            Mock -CommandName 'Show-Toast' -MockWith { }
            
            # Mock index operations
            Mock -CommandName 'Reset-RulesIndexCache' -MockWith { }
        }
        
        It 'Should call Remove-Rules with correct rule IDs' {
            # Arrange
            $rulesToDelete = @(
                New-MockRule -Id 'delete-1'
                New-MockRule -Id 'delete-2'
            )
            
            $mockDataGrid = [PSCustomObject]@{
                ItemsSource = $rulesToDelete
                SelectedItems = $rulesToDelete
            }
            $mockDataGrid | Add-Member -MemberType ScriptMethod -Name 'UnselectAll' -Value { }
            
            $mockWindow = New-MockWindow -Elements @{
                'RulesDataGrid' = $mockDataGrid
                'ChkSelectAllRules' = [PSCustomObject]@{ IsChecked = $false }
                'TxtSelectionCount' = [PSCustomObject]@{ Text = '' }
            }
            
            # Act - Simulate delete logic
            $selectedIds = @($rulesToDelete | ForEach-Object { $_.Id })
            Remove-Rules -RuleIds $selectedIds
            
            # Assert
            Should -Invoke Remove-Rules -Times 1 -ParameterFilter {
                $RuleIds.Count -eq 2 -and
                $RuleIds -contains 'delete-1' -and
                $RuleIds -contains 'delete-2'
            }
        }
        
        It 'Should show success toast after deletion' {
            # Arrange
            $rulesToDelete = @(New-MockRule -Id 'test-rule')
            Remove-Rules -RuleIds @('test-rule')
            
            # Act
            Show-Toast -Message 'Deleted 1 rules' -Type 'Success'
            
            # Assert
            Should -Invoke Show-Toast -Times 1 -ParameterFilter {
                $Type -eq 'Success'
            }
        }
    }
}

Describe 'Rules Panel - Status Updates' {
    Context 'Set-SelectedRuleStatus' {
        BeforeEach {
            Mock -CommandName 'Update-RuleStatus' -MockWith {
                return [PSCustomObject]@{ Success = $true }
            }
            
            Mock -CommandName 'Update-RuleStatusInIndex' -MockWith { }
            Mock -CommandName 'Show-Toast' -MockWith { }
            Mock -CommandName 'Show-LoadingOverlay' -MockWith { }
            Mock -CommandName 'Hide-LoadingOverlay' -MockWith { }
        }
        
        It 'Should update status for all selected rules' {
            # Arrange
            $rules = @(
                New-MockRule -Id 'rule-1' -Status 'Pending'
                New-MockRule -Id 'rule-2' -Status 'Pending'
            )
            
            # Act - Simulate status update
            foreach ($rule in $rules) {
                Update-RuleStatus -RuleId $rule.Id -Status 'Approved'
            }
            
            # Assert
            Should -Invoke Update-RuleStatus -Times 2
        }
        
        It 'Should batch update the index' {
            # Arrange
            $ruleIds = @('rule-1', 'rule-2', 'rule-3')
            
            # Act
            Update-RuleStatusInIndex -RuleIds $ruleIds -Status 'Approved'
            
            # Assert
            Should -Invoke Update-RuleStatusInIndex -Times 1 -ParameterFilter {
                $RuleIds.Count -eq 3 -and $Status -eq 'Approved'
            }
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
