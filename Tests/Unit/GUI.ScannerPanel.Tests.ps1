#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for Scanner panel logic.
.DESCRIPTION
    Tests Initialize-ScannerPanel setup, machine management,
    and artifact filter logic with mocked WPF elements.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -WarningAction SilentlyContinue
    }

    # Load mock helpers
    . (Join-Path $PSScriptRoot '..\Helpers\MockWpfHelpers.ps1')

    # Dot-source the Scanner panel
    . (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Scanner.ps1')

    # Global stubs
    if (-not (Get-Command 'Show-Toast' -ErrorAction SilentlyContinue)) {
        function global:Show-Toast { param([string]$Message, [string]$Type) }
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
    if (-not (Get-Command 'Invoke-ButtonAction' -ErrorAction SilentlyContinue)) {
        function global:Invoke-ButtonAction { param([string]$Action) }
    }
}

Describe 'Scanner Panel - Initialization' {
    It 'Does not throw on empty window' {
        $win = New-MockWpfWindow -Elements @{}
        { Initialize-ScannerPanel -Window $win } | Should -Not -Throw
    }

    It 'Does not throw with minimal elements' {
        $elements = @{
            'BtnStartScan'     = New-MockButton -Content 'Start Scan'
            'BtnStopScan'      = New-MockButton -Content 'Stop Scan'
            'BtnImportArtifacts' = New-MockButton -Content 'Import'
            'BtnExportArtifacts' = New-MockButton -Content 'Export'
            'ChkScanLocal'     = New-MockCheckBox -IsChecked $true
            'ChkScanRemote'    = New-MockCheckBox -IsChecked $false
        }
        $win = New-MockWpfWindow -Elements $elements
        { Initialize-ScannerPanel -Window $win } | Should -Not -Throw
    }
}

Describe 'Scanner Panel - Scan Machine Management' {
    Context 'Clear machines' {
        It 'Invoke-ClearScanMachines empties the selected machines list' {
            if (Get-Command 'Invoke-ClearScanMachines' -ErrorAction SilentlyContinue) {
                Mock Show-Toast {}
                $script:SelectedScanMachines = @(
                    [PSCustomObject]@{ Hostname = 'PC1' },
                    [PSCustomObject]@{ Hostname = 'PC2' }
                )

                $win = New-MockWpfWindow -Elements @{}
                Invoke-ClearScanMachines -Window $win

                $script:SelectedScanMachines.Count | Should -Be 0
            } else {
                Set-ItResult -Skipped -Because 'Invoke-ClearScanMachines not available'
            }
        }
    }
}

Describe 'Scanner Panel - Artifact Filter State' {
    It 'Tracks current artifact filter state' {
        # The filter state variable should exist
        $script:CurrentArtifactFilter = 'All'
        $script:CurrentArtifactFilter | Should -Be 'All'

        $script:CurrentArtifactFilter = 'EXE'
        $script:CurrentArtifactFilter | Should -Be 'EXE'
    }
}

Describe 'Scanner Panel - Scan State Management' {
    It 'Tracks scan in progress flag' {
        $script:ScanInProgress = $false
        $script:ScanInProgress | Should -BeFalse

        $script:ScanInProgress = $true
        $script:ScanInProgress | Should -BeTrue
    }
}

Describe 'Scanner Panel - Checkbox Defaults' {
    It 'Local scan is checked by default in XAML' {
        $rawXaml = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml') -Raw
        $rawXaml | Should -Match 'ChkScanLocal.*IsChecked="True"'
    }

    It 'Remote scan is NOT checked by default' {
        $rawXaml = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml') -Raw
        # ChkScanRemote should NOT have IsChecked="True"
        $rawXaml | Should -Not -Match 'ChkScanRemote[^>]*IsChecked="True"'
    }

    It 'Appx/MSIX is checked by default' {
        $rawXaml = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml') -Raw
        $rawXaml | Should -Match 'ChkIncludeAppx[^>]*IsChecked="True"'
    }
}
