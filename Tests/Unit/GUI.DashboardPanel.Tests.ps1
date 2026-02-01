#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for Dashboard panel logic.
.DESCRIPTION
    Tests Update-DashboardStats and Update-DashboardCharts with mocked
    backend functions and mock WPF window objects. Runs headless.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -WarningAction SilentlyContinue
    }

    # Load mock helpers
    . (Join-Path $PSScriptRoot '..\Helpers\MockWpfHelpers.ps1')

    # Dot-source the Dashboard panel
    . (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Dashboard.ps1')

    # Provide global: stubs for functions the panel calls
    if (-not (Get-Command 'Show-Toast' -ErrorAction SilentlyContinue)) {
        function global:Show-Toast { param([string]$Message, [string]$Type) }
    }
    if (-not (Get-Command 'Update-WorkflowBreadcrumb' -ErrorAction SilentlyContinue)) {
        function global:Update-WorkflowBreadcrumb { param($Window) }
    }
}

Describe 'Dashboard Panel - Update-DashboardStats' {
    BeforeEach {
        # Default mocked elements for Dashboard
        $script:Elements = @{
            'StatMachines'    = New-MockTextBlock
            'StatArtifacts'   = New-MockTextBlock
            'StatRules'       = New-MockTextBlock
            'StatPending'     = New-MockTextBlock
            'StatApproved'    = New-MockTextBlock
            'StatRejected'    = New-MockTextBlock
            'StatPolicies'    = New-MockTextBlock
            'DashRecentScans' = New-MockListBox
            'DashPendingRules'= New-MockListBox
        }
    }

    Context 'With rules data' {
        It 'Populates rule counts from Get-RuleCounts' {
            Mock Get-RuleCounts {
                @{
                    Success   = $true
                    Total     = 150
                    ByStatus  = @{ 'Pending' = 25; 'Approved' = 100; 'Rejected' = 25 }
                    ByRuleType = @{ 'Publisher' = 80; 'Hash' = 50; 'Path' = 20 }
                }
            }
            Mock Get-AllPolicies { @{ Success = $true; Data = @() } }
            Mock Get-ScanResults { @{ Success = $false } }
            Mock Get-RulesFromDatabase { @() }

            $script:DiscoveredMachines = @()
            $script:CurrentScanArtifacts = @()

            $win = New-MockWpfWindow -Elements $script:Elements
            Update-DashboardStats -Window $win

            $script:Elements['StatRules'].Text | Should -Be '150'
            $script:Elements['StatPending'].Text | Should -Be '25'
            $script:Elements['StatApproved'].Text | Should -Be '100'
            $script:Elements['StatRejected'].Text | Should -Be '25'
        }

        It 'Shows machine count from script:DiscoveredMachines' {
            Mock Get-RuleCounts { @{ Success = $false } }
            Mock Get-AllPolicies { @{ Success = $true; Data = @(1,2,3) } }
            Mock Get-ScanResults { @{ Success = $false } }

            $script:DiscoveredMachines = @(
                [PSCustomObject]@{ Hostname = 'PC1' },
                [PSCustomObject]@{ Hostname = 'PC2' },
                [PSCustomObject]@{ Hostname = 'PC3' }
            )
            $script:CurrentScanArtifacts = @()

            $win = New-MockWpfWindow -Elements $script:Elements
            Update-DashboardStats -Window $win

            $script:Elements['StatMachines'].Text | Should -Be '3'
        }

        It 'Shows policy count from Get-AllPolicies' {
            Mock Get-RuleCounts { @{ Success = $false } }
            Mock Get-AllPolicies { @{ Success = $true; Data = @(1,2,3,4,5) } }
            Mock Get-ScanResults { @{ Success = $false } }

            $script:DiscoveredMachines = @()
            $script:CurrentScanArtifacts = @()

            $win = New-MockWpfWindow -Elements $script:Elements
            Update-DashboardStats -Window $win

            $script:Elements['StatPolicies'].Text | Should -Be '5'
        }
    }

    Context 'With zero data' {
        It 'Shows zeros when no rules exist' {
            Mock Get-RuleCounts {
                @{
                    Success    = $true
                    Total      = 0
                    ByStatus   = @{}
                    ByRuleType = @{}
                }
            }
            Mock Get-AllPolicies { @{ Success = $true; Data = @() } }
            Mock Get-ScanResults { @{ Success = $false } }
            Mock Get-RulesFromDatabase { @() }

            $script:DiscoveredMachines = @()
            $script:CurrentScanArtifacts = @()

            $win = New-MockWpfWindow -Elements $script:Elements
            Update-DashboardStats -Window $win

            $script:Elements['StatRules'].Text | Should -Be '0'
            $script:Elements['StatPending'].Text | Should -Be '0'
            $script:Elements['StatMachines'].Text | Should -Be '0'
        }
    }

    Context 'With missing elements (null safety)' {
        It 'Does not throw when elements are missing from window' {
            Mock Get-RuleCounts { @{ Success = $true; Total = 10; ByStatus = @{}; ByRuleType = @{} } }
            Mock Get-AllPolicies { @{ Success = $true; Data = @() } }
            Mock Get-ScanResults { @{ Success = $false } }
            Mock Get-RulesFromDatabase { @() }

            $script:DiscoveredMachines = @()
            $script:CurrentScanArtifacts = @()

            # Empty window — no elements registered
            $win = New-MockWpfWindow -Elements @{}
            { Update-DashboardStats -Window $win } | Should -Not -Throw
        }
    }

    Context 'Pending rules list' {
        It 'Populates DashPendingRules with up to 10 items' {
            Mock Get-RuleCounts {
                @{
                    Success   = $true
                    Total     = 30
                    ByStatus  = @{ 'Pending' = 12; 'Approved' = 18 }
                    ByRuleType = @{}
                }
            }
            Mock Get-AllPolicies { @{ Success = $true; Data = @() } }
            Mock Get-ScanResults { @{ Success = $false } }
            Mock Get-RulesFromDatabase {
                @(
                    [PSCustomObject]@{ RuleType = 'Publisher'; Name = 'Rule 1' },
                    [PSCustomObject]@{ RuleType = 'Hash'; Name = 'Rule 2' },
                    [PSCustomObject]@{ RuleType = 'Publisher'; Name = 'Rule 3' }
                )
            }

            $script:DiscoveredMachines = @()
            $script:CurrentScanArtifacts = @()

            $win = New-MockWpfWindow -Elements $script:Elements
            Update-DashboardStats -Window $win

            $script:Elements['DashPendingRules'].ItemsSource | Should -Not -BeNullOrEmpty
            $script:Elements['DashPendingRules'].ItemsSource.Count | Should -Be 3
        }
    }
}

Describe 'Dashboard Panel - Initialize-DashboardPanel' {
    It 'Does not throw with empty window' {
        Mock Update-DashboardStats {}
        $win = New-MockWpfWindow -Elements @{}
        { Initialize-DashboardPanel -Window $win } | Should -Not -Throw
    }
}
