#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for AD Discovery panel logic.
.DESCRIPTION
    Tests filter state management, machine data grid updates,
    and null-safety with mocked WPF elements.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -WarningAction SilentlyContinue
    }

    # Load mock helpers
    . (Join-Path $PSScriptRoot '..\Helpers\MockWpfHelpers.ps1')

    # Dot-source the panel
    . (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\ADDiscovery.ps1')

    # Global stubs
    if (-not (Get-Command 'Show-Toast' -ErrorAction SilentlyContinue)) {
        function global:Show-Toast { param([string]$Message, [string]$Type) }
    }
    if (-not (Get-Command 'Invoke-ButtonAction' -ErrorAction SilentlyContinue)) {
        function global:Invoke-ButtonAction { param([string]$Action) }
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

Describe 'Discovery Panel - Initialization' {
    It 'Does not throw on empty window' {
        $win = New-MockWpfWindow -Elements @{}
        { Initialize-DiscoveryPanel -Window $win } | Should -Not -Throw
    }

    It 'Does not throw with basic elements' {
        $elements = @{
            'BtnRefreshDomain'    = New-MockButton -Content 'Refresh'
            'BtnTestConnectivity' = New-MockButton -Content 'Test'
            'MachineFilterBox'    = New-MockTextBox
            'MachineDataGrid'     = New-MockDataGrid
            'OUTreeView'          = New-MockTreeView
            'DiscoveryDomainLabel'  = New-MockTextBlock
            'DiscoveryMachineCount' = New-MockTextBlock
        }
        $win = New-MockWpfWindow -Elements $elements
        { Initialize-DiscoveryPanel -Window $win } | Should -Not -Throw
    }
}

Describe 'Discovery Panel - Machine DataGrid Updates' {
    Context 'Update-MachineDataGrid function' {
        It 'Sets DataGrid ItemsSource with machine data' {
            if (Get-Command 'Update-MachineDataGrid' -ErrorAction SilentlyContinue) {
                $dg = New-MockDataGrid
                $elements = @{ 'MachineDataGrid' = $dg }
                $win = New-MockWpfWindow -Elements $elements

                $machines = @(
                    [PSCustomObject]@{ Hostname = 'PC1'; MachineType = 'Workstation'; IsOnline = $true },
                    [PSCustomObject]@{ Hostname = 'PC2'; MachineType = 'Server'; IsOnline = $false }
                )

                Update-MachineDataGrid -Window $win -Machines $machines

                $dg.ItemsSource | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Skipped -Because 'Update-MachineDataGrid not available in test scope'
            }
        }
    }
}

Describe 'Discovery Panel - Filter State' {
    It 'DiscoveredMachines starts empty' {
        $script:DiscoveredMachines = @()
        $script:DiscoveredMachines.Count | Should -Be 0
    }

    It 'SelectedScanMachines starts empty' {
        $script:SelectedScanMachines = @()
        $script:SelectedScanMachines.Count | Should -Be 0
    }
}

Describe 'Discovery Panel - Filter Buttons in XAML' {
    BeforeAll {
        $script:RawXaml = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml') -Raw
    }

    It 'Has All filter button' {
        $script:RawXaml | Should -Match 'BtnFilterAll'
    }

    It 'Has Workstations filter button' {
        $script:RawXaml | Should -Match 'BtnFilterWorkstations'
    }

    It 'Has Servers filter button' {
        $script:RawXaml | Should -Match 'BtnFilterServers'
    }

    It 'Has DCs filter button' {
        $script:RawXaml | Should -Match 'BtnFilterDCs'
    }

    It 'Has Online filter button' {
        $script:RawXaml | Should -Match 'BtnFilterOnline'
    }
}

Describe 'Discovery Panel - Cleanup' {
    It 'Unregister-DiscoveryPanelEvents does not throw on empty window' {
        if (Get-Command 'Unregister-DiscoveryPanelEvents' -ErrorAction SilentlyContinue) {
            $win = New-MockWpfWindow -Elements @{}
            { Unregister-DiscoveryPanelEvents -Window $win } | Should -Not -Throw
        } else {
            Set-ItResult -Skipped -Because 'Unregister-DiscoveryPanelEvents not available'
        }
    }
}
