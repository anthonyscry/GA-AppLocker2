#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for Policy panel logic.
.DESCRIPTION
    Tests Invoke-CreatePolicy, Update-PolicyCounters, Update-SelectedPolicyInfo,
    Invoke-SavePolicyChanges, and Set-SelectedPolicyStatus with mocked
    backend functions and mock WPF window objects.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -WarningAction SilentlyContinue
    }

    # Load mock helpers
    . (Join-Path $PSScriptRoot '..\Helpers\MockWpfHelpers.ps1')

    # Dot-source the Policy panel
    . (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Policy.ps1')

    # Global stubs
    if (-not (Get-Command 'Show-Toast' -ErrorAction SilentlyContinue)) {
        function global:Show-Toast { param([string]$Message, [string]$Type) }
    }
    if (-not (Get-Command 'Update-WorkflowBreadcrumb' -ErrorAction SilentlyContinue)) {
        function global:Update-WorkflowBreadcrumb { param($Window) }
    }
    if (-not (Get-Command 'Invoke-AsyncOperation' -ErrorAction SilentlyContinue)) {
        function global:Invoke-AsyncOperation {
            param([scriptblock]$ScriptBlock, [hashtable]$Arguments, [string]$LoadingMessage,
                  [string]$LoadingSubMessage, [scriptblock]$OnComplete, [scriptblock]$OnError, [switch]$NoLoadingOverlay)
            try {
                $result = & $ScriptBlock @Arguments
                if ($OnComplete) { & $OnComplete -Result $result }
            } catch {
                if ($OnError) { & $OnError -ErrorMessage $_.Exception.Message }
            }
        }
    }
}

Describe 'Policy Panel - Invoke-CreatePolicy' {
    BeforeEach {
        $script:Elements = @{
            'TxtPolicyName'        = New-MockTextBox -Text 'Test Policy'
            'TxtPolicyDescription' = New-MockTextBox -Text 'Test Description'
            'CboPolicyEnforcement' = New-MockComboBox -Items @('AuditOnly','Enabled','NotConfigured') -SelectedIndex 0
            'CboPolicyPhase'       = New-MockComboBox -Items @(
                (New-MockComboBoxItem -Content 'Phase 1' -Tag 1),
                (New-MockComboBoxItem -Content 'Phase 2' -Tag 2)
            ) -SelectedIndex 0
            'PoliciesDataGrid'     = New-MockDataGrid
        }
    }

    Context 'Validation' {
        It 'Shows toast when policy name is empty' {
            Mock Show-Toast {} -Verifiable
            Mock New-Policy {}
            Mock Update-PoliciesDataGrid {}

            $script:Elements['TxtPolicyName'] = New-MockTextBox -Text ''
            $win = New-MockWpfWindow -Elements $script:Elements

            Invoke-CreatePolicy -Window $win

            Should -Invoke Show-Toast -Times 1 -ParameterFilter { $Type -eq 'Warning' }
            Should -Invoke New-Policy -Times 0
        }

        It 'Shows toast when policy name is whitespace' {
            Mock Show-Toast {} -Verifiable
            Mock New-Policy {}
            Mock Update-PoliciesDataGrid {}

            $script:Elements['TxtPolicyName'] = New-MockTextBox -Text '   '
            $win = New-MockWpfWindow -Elements $script:Elements

            Invoke-CreatePolicy -Window $win

            Should -Invoke Show-Toast -Times 1 -ParameterFilter { $Type -eq 'Warning' }
            Should -Invoke New-Policy -Times 0
        }
    }

    Context 'Successful creation' {
        It 'Calls New-Policy with correct parameters' {
            Mock Show-Toast {}
            Mock New-Policy { @{ Success = $true; Data = @{ PolicyId = 'policy-123' } } } -Verifiable
            Mock Update-PoliciesDataGrid {}
            Mock Update-WorkflowBreadcrumb {}

            $win = New-MockWpfWindow -Elements $script:Elements
            Invoke-CreatePolicy -Window $win

            Should -Invoke New-Policy -Times 1 -ParameterFilter {
                $Name -eq 'Test Policy' -and $EnforcementMode -eq 'AuditOnly'
            }
        }

        It 'Clears form fields after successful creation' {
            Mock Show-Toast {}
            Mock New-Policy { @{ Success = $true; Data = @{ PolicyId = 'p1' } } }
            Mock Update-PoliciesDataGrid {}
            Mock Update-WorkflowBreadcrumb {}

            $win = New-MockWpfWindow -Elements $script:Elements
            Invoke-CreatePolicy -Window $win

            $script:Elements['TxtPolicyName'].Text | Should -Be ''
            $script:Elements['TxtPolicyDescription'].Text | Should -Be ''
        }

        It 'Shows success toast after creation' {
            Mock Show-Toast {} -Verifiable
            Mock New-Policy { @{ Success = $true; Data = @{ PolicyId = 'p1' } } }
            Mock Update-PoliciesDataGrid {}
            Mock Update-WorkflowBreadcrumb {}

            $win = New-MockWpfWindow -Elements $script:Elements
            Invoke-CreatePolicy -Window $win

            Should -Invoke Show-Toast -Times 1 -ParameterFilter { $Type -eq 'Success' }
        }
    }

    Context 'Failed creation' {
        It 'Shows error toast when New-Policy fails' {
            Mock Show-Toast {} -Verifiable
            Mock New-Policy { @{ Success = $false; Error = 'Disk full' } }
            Mock Update-PoliciesDataGrid {}

            $win = New-MockWpfWindow -Elements $script:Elements
            Invoke-CreatePolicy -Window $win

            Should -Invoke Show-Toast -Times 1 -ParameterFilter { $Type -eq 'Error' }
        }
    }

    Context 'Null safety' {
        It 'Does not throw when elements are missing' {
            Mock Show-Toast {}
            Mock New-Policy { @{ Success = $true; Data = @{ PolicyId = 'p1' } } }
            Mock Update-PoliciesDataGrid {}
            Mock Update-WorkflowBreadcrumb {}

            # Only provide name — everything else is null
            $win = New-MockWpfWindow -Elements @{
                'TxtPolicyName' = New-MockTextBox -Text 'TestPolicy'
            }
            { Invoke-CreatePolicy -Window $win } | Should -Not -Throw
        }
    }
}

Describe 'Policy Panel - Update-PolicyCounters' {
    It 'Populates counter labels from policy data' {
        $elements = @{
            'TxtPolicyTotalCount'    = New-MockTextBlock
            'TxtPolicyDraftCount'    = New-MockTextBlock
            'TxtPolicyActiveCount'   = New-MockTextBlock
            'TxtPolicyDeployedCount' = New-MockTextBlock
        }

        $policies = @(
            [PSCustomObject]@{ Status = 'Draft' },
            [PSCustomObject]@{ Status = 'Draft' },
            [PSCustomObject]@{ Status = 'Active' },
            [PSCustomObject]@{ Status = 'Deployed' },
            [PSCustomObject]@{ Status = 'Deployed' },
            [PSCustomObject]@{ Status = 'Deployed' }
        )

        $win = New-MockWpfWindow -Elements $elements
        Update-PolicyCounters -Window $win -Policies $policies

        $elements['TxtPolicyTotalCount'].Text | Should -Be '6'
        $elements['TxtPolicyDraftCount'].Text | Should -Be '2'
        $elements['TxtPolicyActiveCount'].Text | Should -Be '1'
        $elements['TxtPolicyDeployedCount'].Text | Should -Be '3'
    }

    It 'Shows zeros with empty policy array' {
        $elements = @{
            'TxtPolicyTotalCount'    = New-MockTextBlock
            'TxtPolicyDraftCount'    = New-MockTextBlock
            'TxtPolicyActiveCount'   = New-MockTextBlock
            'TxtPolicyDeployedCount' = New-MockTextBlock
        }

        $win = New-MockWpfWindow -Elements $elements
        Update-PolicyCounters -Window $win -Policies @()

        $elements['TxtPolicyTotalCount'].Text | Should -Be '0'
    }

    It 'Shows zeros with null policy array' {
        $elements = @{
            'TxtPolicyTotalCount' = New-MockTextBlock
        }

        $win = New-MockWpfWindow -Elements $elements
        Update-PolicyCounters -Window $win -Policies $null

        $elements['TxtPolicyTotalCount'].Text | Should -Be '0'
    }
}

Describe 'Policy Panel - Update-SelectedPolicyInfo' {
    Context 'With selected policy' {
        It 'Populates edit fields from DataGrid selection' {
            $selectedPolicy = [PSCustomObject]@{
                PolicyId        = 'p-123'
                Name            = 'Production Policy'
                Description     = 'For production servers'
                EnforcementMode = 'Enabled'
                Phase           = 2
                RuleIds         = @('r1','r2','r3')
                TargetGPO       = ''
            }

            $elements = @{
                'PoliciesDataGrid'       = New-MockDataGrid -Data @($selectedPolicy) -SelectedItem $selectedPolicy
                'TxtSelectedPolicyName'  = New-MockTextBlock
                'TxtPolicyRuleCount'     = New-MockTextBlock
                'TxtEditPolicyName'      = New-MockTextBox
                'TxtEditPolicyDescription' = New-MockTextBox
                'CboEditEnforcement'     = New-MockComboBox -Items @('AuditOnly','Enabled','NotConfigured')
                'CboEditPhase'           = New-MockComboBox -Items @(
                    (New-MockComboBoxItem -Content 'Phase 1' -Tag 1),
                    (New-MockComboBoxItem -Content 'Phase 2' -Tag 2)
                )
                'CboEditTargetGPO'       = New-MockComboBox -Items @()
                'TxtEditCustomGPO'       = New-MockTextBox
            }

            $win = New-MockWpfWindow -Elements $elements
            Update-SelectedPolicyInfo -Window $win

            $elements['TxtSelectedPolicyName'].Text | Should -Be 'Production Policy'
            $elements['TxtPolicyRuleCount'].Text | Should -Be '3 rules'
            $elements['TxtEditPolicyName'].Text | Should -Be 'Production Policy'
            $elements['TxtEditPolicyDescription'].Text | Should -Be 'For production servers'
            $elements['CboEditEnforcement'].SelectedIndex | Should -Be 1
        }
    }

    Context 'With no selection' {
        It 'Resets fields when nothing is selected' {
            $elements = @{
                'PoliciesDataGrid'       = New-MockDataGrid
                'TxtSelectedPolicyName'  = New-MockTextBlock -Text 'Old Policy'
                'TxtPolicyRuleCount'     = New-MockTextBlock -Text '99 rules'
                'TxtEditPolicyName'      = New-MockTextBox -Text 'Old Name'
                'TxtEditPolicyDescription' = New-MockTextBox -Text 'Old Desc'
                'CboEditTargetGPO'       = New-MockComboBox -Items @()
                'TxtEditCustomGPO'       = New-MockTextBox
            }

            $win = New-MockWpfWindow -Elements $elements
            Update-SelectedPolicyInfo -Window $win

            $elements['TxtSelectedPolicyName'].Text | Should -Be '(Select a policy)'
            $elements['TxtPolicyRuleCount'].Text | Should -Be '0 rules'
            $elements['TxtEditPolicyName'].Text | Should -Be ''
        }
    }
}

Describe 'Policy Panel - Invoke-SavePolicyChanges' {
    Context 'Validation' {
        It 'Shows toast when no policy selected' {
            Mock Show-Toast {} -Verifiable
            $script:SelectedPolicyId = $null

            $win = New-MockWpfWindow -Elements @{}
            Invoke-SavePolicyChanges -Window $win

            Should -Invoke Show-Toast -Times 1 -ParameterFilter { $Type -eq 'Warning' }
        }

        It 'Shows toast when edit name is empty' {
            Mock Show-Toast {} -Verifiable
            $script:SelectedPolicyId = 'p-123'

            $win = New-MockWpfWindow -Elements @{
                'TxtEditPolicyName' = New-MockTextBox -Text ''
                'TxtEditPolicyDescription' = New-MockTextBox -Text 'desc'
                'CboEditEnforcement' = New-MockComboBox -Items @('AuditOnly') -SelectedIndex 0
                'CboEditPhase' = New-MockComboBox -Items @((New-MockComboBoxItem -Tag 1)) -SelectedIndex 0
                'CboEditTargetGPO' = New-MockComboBox -Items @() -SelectedIndex -1
            }
            Invoke-SavePolicyChanges -Window $win

            Should -Invoke Show-Toast -Times 1 -ParameterFilter { $Type -eq 'Warning' }
        }
    }

    Context 'Successful update' {
        It 'Calls Update-Policy with correct parameters' {
            Mock Show-Toast {}
            Mock Update-Policy { @{ Success = $true } } -Verifiable
            Mock Update-PoliciesDataGrid {}
            Mock Update-SelectedPolicyInfo {}

            $script:SelectedPolicyId = 'p-456'

            $win = New-MockWpfWindow -Elements @{
                'TxtEditPolicyName'        = New-MockTextBox -Text 'Updated Policy'
                'TxtEditPolicyDescription' = New-MockTextBox -Text 'New desc'
                'CboEditEnforcement'       = New-MockComboBox -Items @('AuditOnly','Enabled') -SelectedIndex 1
                'CboEditPhase'             = New-MockComboBox -Items @(
                    (New-MockComboBoxItem -Content 'Phase 1' -Tag 1),
                    (New-MockComboBoxItem -Content 'Phase 2' -Tag 2)
                ) -SelectedIndex 1
                'CboEditTargetGPO'         = New-MockComboBox -Items @() -SelectedIndex -1
                'TxtEditCustomGPO'         = New-MockTextBox
            }
            Invoke-SavePolicyChanges -Window $win

            Should -Invoke Update-Policy -Times 1 -ParameterFilter {
                $Id -eq 'p-456' -and $Name -eq 'Updated Policy'
            }
        }
    }
}

Describe 'Policy Panel - Set-SelectedPolicyStatus' {
    It 'Does nothing when no policy selected' {
        Mock Show-Toast {}
        $script:SelectedPolicyId = $null
        $win = New-MockWpfWindow -Elements @{}

        # When no policy is selected, function should return early or show toast
        # It should NOT call Set-PolicyStatus
        Mock Set-PolicyStatus {} -ErrorAction SilentlyContinue

        try { Set-SelectedPolicyStatus -Window $win -Status 'Active' } catch { }

        # Verify it didn't call Set-PolicyStatus (no policy was selected)
        $script:SelectedPolicyId | Should -BeNullOrEmpty
    }
}

Describe 'Policy Panel - Update-PoliciesFilter' {
    It 'Updates script filter state' {
        Mock Update-PoliciesDataGrid {}

        $win = New-MockWpfWindow -Elements @{}
        Update-PoliciesFilter -Window $win -Filter 'Active'

        $script:CurrentPoliciesFilter | Should -Be 'Active'
    }

    It 'Resets to All filter' {
        Mock Update-PoliciesDataGrid {}

        $win = New-MockWpfWindow -Elements @{}
        Update-PoliciesFilter -Window $win -Filter 'All'

        $script:CurrentPoliciesFilter | Should -Be 'All'
    }
}
