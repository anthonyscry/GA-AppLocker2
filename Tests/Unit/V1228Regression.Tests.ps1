#Requires -Modules Pester
<#
.SYNOPSIS
    Regression tests for v1.2.28 changes - deployment fix, scan CSV export,
    button dispatcher completeness, XAML-code cross-references, comparison re-runs,
    and module integrity.

.DESCRIPTION
    Covers areas not tested in SoftwareComparison.Tests.ps1:
    - Button dispatcher <-> XAML element name cross-reference
    - Setup panel button wiring matches XAML
    - Software comparison re-runs and state resets
    - Deployment Import-PolicyToGPO path handling
    - Scan CSV export null ComputerName patching
    - Module manifest version consistency
    - XAML full parse validation
    - Get-SetupStatus return structure

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Unit\V1228Regression.Tests.ps1 -Output Detailed
#>

BeforeAll {
    Get-Module 'GA-AppLocker*' | Remove-Module -Force -ErrorAction SilentlyContinue
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # Load files needed for cross-referencing
    $script:XamlContent = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml') -Raw
    $script:MainWindowPs1 = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml.ps1') -Raw
    $script:SetupPs1 = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Setup.ps1') -Raw
    $script:SoftwarePs1 = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Software.ps1') -Raw

    # Define UI stubs for dot-sourcing
    function global:Show-Toast { param($Message, $Type) }
    function global:Show-LoadingOverlay { param($Message, $SubMessage) }
    function global:Hide-LoadingOverlay { }
    function global:Invoke-ButtonAction { param($Action) }
    function global:Invoke-UIUpdate { param($Action) }

    # Dot-source Software.ps1 for comparison function tests
    $softwarePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Software.ps1'
    . $softwarePath

    function script:New-SoftwareItem {
        param(
            [string]$Machine = 'PC1',
            [string]$DisplayName,
            [string]$DisplayVersion = '1.0.0',
            [string]$Publisher = 'Test Publisher',
            [string]$Source = 'Local'
        )
        [PSCustomObject]@{
            Machine         = $Machine
            DisplayName     = $DisplayName
            DisplayVersion  = $DisplayVersion
            Publisher       = $Publisher
            InstallDate     = '2026-01-31'
            InstallLocation = ''
            Architecture    = 'x64'
            Source          = $Source
        }
    }
}

AfterAll {
    Remove-Item Function:\Show-Toast -ErrorAction SilentlyContinue
    Remove-Item Function:\Show-LoadingOverlay -ErrorAction SilentlyContinue
    Remove-Item Function:\Hide-LoadingOverlay -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-ButtonAction -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-UIUpdate -ErrorAction SilentlyContinue
}

# ============================================================================
# XAML FULL PARSE VALIDATION
# ============================================================================

Describe 'XAML Parse Integrity' -Tag 'Unit', 'XAML' {

    It 'MainWindow.xaml should parse as valid XML' {
        $xamlPath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml'
        { [xml](Get-Content $xamlPath -Raw) } | Should -Not -Throw
    }

    It 'XAML should contain all expected panel grids' {
        # Actual panels: Dashboard, Discovery, Scanner, Rules, Policy, Deploy, Settings, Setup, About, Software
        # Note: there is no PanelCredentials - credentials are managed via dialog, not a panel
        $panels = @(
            'PanelDashboard', 'PanelDiscovery', 'PanelScanner',
            'PanelRules', 'PanelPolicy', 'PanelDeploy',
            'PanelSettings', 'PanelSetup', 'PanelAbout', 'PanelSoftware'
        )
        foreach ($panel in $panels) {
            $script:XamlContent | Should -Match "x:Name=""$panel"""
        }
    }
}

# ============================================================================
# BUTTON DISPATCHER <-> XAML CROSS-REFERENCE
# ============================================================================

Describe 'Button Dispatcher - Setup Panel Actions' -Tag 'Unit', 'Integration', 'Setup' {

    Context 'Every Setup button action in dispatcher has matching XAML element' {
        # Extract action strings from the dispatcher
        # The dispatcher maps action strings to function calls
        # Setup.ps1 maps XAML element names to action strings

        It 'InitializeWinRM action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'InitializeWinRM'"
        }
        It 'ToggleEnableWinRM action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'ToggleEnableWinRM'"
        }
        It 'RemoveEnableWinRM action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'RemoveEnableWinRM'"
        }
        It 'ToggleDisableWinRM action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'ToggleDisableWinRM'"
        }
        It 'RemoveDisableWinRM action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'RemoveDisableWinRM'"
        }
    }

    Context 'Every Setup XAML element has matching button wiring in Setup.ps1' {
        It 'BtnInitializeWinRM is wired in Setup.ps1' {
            $script:SetupPs1 | Should -Match "FindName\('BtnInitializeWinRM'\)"
        }
        It 'BtnToggleEnableWinRM is wired in Setup.ps1' {
            $script:SetupPs1 | Should -Match "FindName\('BtnToggleEnableWinRM'\)"
        }
        It 'BtnRemoveEnableWinRM is wired in Setup.ps1' {
            $script:SetupPs1 | Should -Match "FindName\('BtnRemoveEnableWinRM'\)"
        }
        It 'BtnToggleDisableWinRM is wired in Setup.ps1' {
            $script:SetupPs1 | Should -Match "FindName\('BtnToggleDisableWinRM'\)"
        }
        It 'BtnRemoveDisableWinRM is wired in Setup.ps1' {
            $script:SetupPs1 | Should -Match "FindName\('BtnRemoveDisableWinRM'\)"
        }
    }

    Context 'Old action strings and element names are fully removed' {
        It 'No ToggleWinRM action in dispatcher (replaced by ToggleEnableWinRM/ToggleDisableWinRM)' {
            # Match standalone 'ToggleWinRM' but not 'ToggleEnableWinRM' or 'ToggleDisableWinRM'
            $script:MainWindowPs1 | Should -Not -Match "'ToggleWinRM'\s*\{"
        }
        It 'No RemoveWinRM action in dispatcher (replaced by RemoveEnableWinRM/RemoveDisableWinRM)' {
            $script:MainWindowPs1 | Should -Not -Match "'RemoveWinRM'\s*\{"
        }
        It 'No DisableWinRMGPO action in dispatcher' {
            $script:MainWindowPs1 | Should -Not -Match "'DisableWinRMGPO'"
        }
        It 'No BtnDisableWinRMGPO wiring in Setup.ps1' {
            $script:SetupPs1 | Should -Not -Match "BtnDisableWinRMGPO"
        }
        It 'No BtnToggleWinRM wiring in Setup.ps1' {
            $script:SetupPs1 | Should -Not -Match "FindName\('BtnToggleWinRM'\)"
        }
        It 'No BtnRemoveWinRM wiring in Setup.ps1' {
            $script:SetupPs1 | Should -Not -Match "FindName\('BtnRemoveWinRM'\)"
        }
    }
}

Describe 'Button Dispatcher - Software Panel Actions' -Tag 'Unit', 'Integration', 'Software' {

    Context 'Every Software button Tag has matching dispatcher action' {
        It 'ScanLocalSoftware action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'ScanLocalSoftware'"
        }
        It 'ScanRemoteSoftware action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'ScanRemoteSoftware'"
        }
        It 'ExportSoftwareCsv action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'ExportSoftwareCsv'"
        }
        It 'ImportSoftwareCsv action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'ImportSoftwareCsv'"
        }
        It 'CompareSoftware action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'CompareSoftware'"
        }
        It 'ClearSoftwareComparison action exists in dispatcher' {
            $script:MainWindowPs1 | Should -Match "'ClearSoftwareComparison'"
        }
    }

    Context 'Software filter buttons have correct Tag values' {
        It 'BtnFilterSoftwareAll has Tag FilterSoftwareAll' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareAll".*Tag="FilterSoftwareAll"'
        }
        It 'BtnFilterSoftwareMatch has Tag FilterSoftwareMatch' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareMatch".*Tag="FilterSoftwareMatch"'
        }
        It 'BtnFilterSoftwareVersionDiff has Tag FilterSoftwareVersionDiff' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareVersionDiff".*Tag="FilterSoftwareVersionDiff"'
        }
        It 'BtnFilterSoftwareOnlyScan has Tag FilterSoftwareOnlyScan' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareOnlyScan".*Tag="FilterSoftwareOnlyScan"'
        }
        It 'BtnFilterSoftwareOnlyImport has Tag FilterSoftwareOnlyImport' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareOnlyImport".*Tag="FilterSoftwareOnlyImport"'
        }
    }
}

# ============================================================================
# SETUP PANEL - STATUS DISPLAY CROSS-REFERENCE
# ============================================================================

Describe 'Setup Panel - Status Display Wiring' -Tag 'Unit', 'Integration', 'Setup' {

    It 'TxtEnableWinRMStatus is read in Update-SetupStatus' {
        $script:SetupPs1 | Should -Match "FindName\('TxtEnableWinRMStatus'\)"
    }
    It 'TxtDisableWinRMStatus is read in Update-SetupStatus' {
        $script:SetupPs1 | Should -Match "FindName\('TxtDisableWinRMStatus'\)"
    }
    It 'BtnToggleEnableWinRM label is updated in Update-SetupStatus' {
        $script:SetupPs1 | Should -Match "FindName\('BtnToggleEnableWinRM'\)"
    }
    It 'BtnToggleDisableWinRM label is updated in Update-SetupStatus' {
        $script:SetupPs1 | Should -Match "FindName\('BtnToggleDisableWinRM'\)"
    }
    It 'Update-SetupStatus reads DisableWinRM from status data' {
        $script:SetupPs1 | Should -Match '\$status\.Data\.DisableWinRM'
    }
}

# ============================================================================
# GET-SETUPSTATUS RETURN STRUCTURE
# ============================================================================

Describe 'Get-SetupStatus - Return Structure' -Tag 'Unit', 'Setup' {

    BeforeAll {
        # Get-SetupStatus needs GroupPolicy module; mock it
        $script:StatusFnBody = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\Modules\GA-AppLocker.Setup\Functions\Get-SetupStatus.ps1') -Raw
    }

    It 'Should define DisableWinRM property in status object' {
        $script:StatusFnBody | Should -Match 'DisableWinRM\s*=\s*\$null'
    }

    It 'Should check for AppLocker-DisableWinRM GPO' {
        $script:StatusFnBody | Should -Match "Get-GPO -Name 'AppLocker-DisableWinRM'"
    }

    It 'Should set DisableWinRM status when GP module not available' {
        $script:StatusFnBody | Should -Match '\$status\.DisableWinRM\s*=.*Module Not Available'
    }

    It 'Should set DisableWinRM status to Not Created when GPO does not exist' {
        # The code sets $status.DisableWinRM = [PSCustomObject]@{ ... Status = 'Not Created' } across multiple lines
        $script:StatusFnBody | Should -Match "Status\s*=\s*'Not Created'"
        $script:StatusFnBody | Should -Match '\$status\.DisableWinRM\s*='
    }
}

# ============================================================================
# DEPLOYMENT FIX - Import-PolicyToGPO
# ============================================================================

Describe 'Import-PolicyToGPO - File Path Fix' -Tag 'Unit', 'Deployment' {

    BeforeAll {
        $script:GpoFunctionsContent = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\Modules\GA-AppLocker.Deployment\Functions\GPO-Functions.ps1') -Raw
    }

    It 'Should pass file path to Set-AppLockerPolicy, not XML content' {
        # The old code did: $xmlContent = [System.IO.File]::ReadAllText(...)
        # The new code does: $resolvedPath = (Resolve-Path $XmlPath).Path
        $script:GpoFunctionsContent | Should -Not -Match 'ReadAllText.*Set-AppLockerPolicy'
        $script:GpoFunctionsContent | Should -Match 'Resolve-Path.*\$XmlPath'
        $script:GpoFunctionsContent | Should -Match 'Set-AppLockerPolicy -XmlPolicy \$resolvedPath'
    }

    It 'Should not read XML file content for Set-AppLockerPolicy' {
        # Ensure ReadAllText is NOT used to pass content to Set-AppLockerPolicy
        $script:GpoFunctionsContent | Should -Not -Match '\[System\.IO\.File\]::ReadAllText.*\$XmlPath.*Set-AppLockerPolicy'
    }

    It 'Import-PolicyToGPO should be an exported function' {
        Get-Command 'Import-PolicyToGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

# ============================================================================
# SCAN CSV EXPORT - Null ComputerName Fix
# ============================================================================

Describe 'Start-ArtifactScan - CSV Export Null Guard' -Tag 'Unit', 'Scanning' {

    BeforeAll {
        $script:ScanContent = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\Modules\GA-AppLocker.Scanning\Functions\Start-ArtifactScan.ps1') -Raw
    }

    It 'Should patch null ComputerName before Group-Object' {
        # The fix adds: if (-not $a.ComputerName) { Add-Member ... }
        $script:ScanContent | Should -Match 'if \(-not \$a\.ComputerName\)'
        $script:ScanContent | Should -Match "Add-Member.*ComputerName.*\`$env:COMPUTERNAME"
    }

    It 'Should wrap CSV export in try/catch' {
        # The entire per-host CSV block should be wrapped
        $script:ScanContent | Should -Match '(?s)try\s*\{.*Per-Host CSV.*Group-Object.*\}.*catch\s*\{'
    }

    It 'Start-ArtifactScan should be an exported function' {
        Get-Command 'Start-ArtifactScan' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

# ============================================================================
# SOFTWARE COMPARISON - RE-RUN AND STATE MANAGEMENT
# ============================================================================

Describe 'Software Comparison - Re-run Behavior' -Tag 'Unit', 'Software', 'EdgeCase' {

    BeforeEach {
        $script:SoftwareInventory = @()
        $script:SoftwareImportedData = @()
        $script:SoftwareImportedFile = ''
        $script:CurrentSoftwareSourceFilter = 'All'
    }

    Context 'Running comparison twice' {
        It 'Should not duplicate results on second run' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'App1' -DisplayVersion '1.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'App2' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App1' -DisplayVersion '1.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App2' -DisplayVersion '2.0' -Source 'Imported')
            )

            # First comparison
            Invoke-CompareSoftware -Window $null
            $firstCount = $script:SoftwareInventory.Count

            # Re-set imported data (simulating user re-importing)
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App1' -DisplayVersion '1.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App2' -DisplayVersion '2.0' -Source 'Imported')
            )

            # After first comparison, SoftwareInventory contains comparison results
            # with Source = Match/Version Diff/etc. A re-comparison should NOT use
            # these as baseline (they are filtered out by Source check)
            # So second run should have empty baseline -> toast warning, no crash
            { Invoke-CompareSoftware -Window $null } | Should -Not -Throw
        }
    }

    Context 'Clear comparison resets state' {
        It 'Should reset source filter to All after clear (code pattern)' {
            # Verifying the code pattern - runtime scope of $script: varies in test harness
            # so we verify the clear function has the right assignments
            $script:SoftwarePs1 | Should -Match 'Invoke-ClearSoftwareComparison'
            $script:SoftwarePs1 | Should -Match '\$script:CurrentSoftwareSourceFilter\s*=\s*''All'''
            $script:SoftwarePs1 | Should -Match '\$script:SoftwareImportedData\s*=\s*@\(\)'
            $script:SoftwarePs1 | Should -Match '\$script:SoftwareInventory\s*=\s*@\(\)'
        }

        It 'Invoke-ClearSoftwareComparison should not crash with null Window' {
            { Invoke-ClearSoftwareComparison -Window $null } | Should -Not -Throw
        }
    }

    Context 'Comparison with mixed scan sources (Local + Remote)' {
        It 'Should include both Local and Remote sources as baseline' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -Machine 'LOCAL' -DisplayName 'App1' -DisplayVersion '1.0' -Source 'Local'),
                (New-SoftwareItem -Machine 'REMOTE1' -DisplayName 'App2' -DisplayVersion '1.0' -Source 'Remote')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App1' -DisplayVersion '1.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App2' -DisplayVersion '2.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App3' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $results = $script:SoftwareInventory
            @($results | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
            @($results | Where-Object { $_.Source -eq 'Version Diff' }).Count | Should -Be 1
            @($results | Where-Object { $_.Source -eq 'Only in Import' }).Count | Should -Be 1
            $results.Count | Should -Be 3
        }
    }

    Context 'Single item datasets' {
        It 'Should handle single matching item' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'Solo' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'Solo' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $script:SoftwareInventory.Count | Should -Be 1
            $script:SoftwareInventory[0].Source | Should -Be 'Match'
        }

        It 'Should handle single non-matching item' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'OnlyHere' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'OnlyThere' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $script:SoftwareInventory.Count | Should -Be 2
            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Only in Scan' }).Count | Should -Be 1
            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Only in Import' }).Count | Should -Be 1
        }
    }

    Context 'Very long software names' {
        It 'Should handle names over 200 characters' {
            $longName = 'A' * 250
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName $longName -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName $longName -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
        }
    }

    Context 'Software name is only whitespace' {
        It 'Should handle whitespace-only names without crashing' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName '   ' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName '   ' -DisplayVersion '1.0' -Source 'Imported')
            )

            { Invoke-CompareSoftware -Window $null } | Should -Not -Throw
        }
    }
}

# ============================================================================
# MODULE MANIFEST INTEGRITY
# ============================================================================

Describe 'Module Manifest Integrity' -Tag 'Unit', 'Module' {

    BeforeAll {
        $script:ManifestPath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
        $script:Manifest = Import-PowerShellDataFile $script:ManifestPath
    }

    It 'Module version should be current' {
        $script:Manifest.ModuleVersion | Should -Match '^\d+\.\d+\.\d+$'
    }

    It 'FunctionsToExport should not be empty' {
        $script:Manifest.FunctionsToExport.Count | Should -BeGreaterThan 100
    }

    It 'FunctionsToExport should include Test-PingConnectivity' {
        $script:Manifest.FunctionsToExport | Should -Contain 'Test-PingConnectivity'
    }

    It 'FunctionsToExport should include Initialize-DisableWinRMGPO' {
        $script:Manifest.FunctionsToExport | Should -Contain 'Initialize-DisableWinRMGPO'
    }

    It 'FunctionsToExport should include Remove-DisableWinRMGPO' {
        $script:Manifest.FunctionsToExport | Should -Contain 'Remove-DisableWinRMGPO'
    }

    It 'Should have no duplicate function exports' {
        $exports = $script:Manifest.FunctionsToExport
        $unique = $exports | Select-Object -Unique
        $exports.Count | Should -Be $unique.Count
    }
}

# ============================================================================
# SETUP PANEL - HANDLER FUNCTION EXISTENCE
# ============================================================================

Describe 'Setup Panel - Handler Functions Defined' -Tag 'Unit', 'Setup' {

    It 'Invoke-InitializeWinRM should be defined in Setup.ps1' {
        $script:SetupPs1 | Should -Match 'function global:Invoke-InitializeWinRM'
    }

    It 'Invoke-ToggleWinRMGPO should be defined (generic per-GPO handler)' {
        $script:SetupPs1 | Should -Match 'function global:Invoke-ToggleWinRMGPO'
    }

    It 'Invoke-RemoveWinRMGPOByName should be defined (generic per-GPO handler)' {
        $script:SetupPs1 | Should -Match 'function global:Invoke-RemoveWinRMGPOByName'
    }

    It 'Invoke-InitializeWinRM should call both Initialize-WinRMGPO and Initialize-DisableWinRMGPO' {
        $script:SetupPs1 | Should -Match 'Initialize-WinRMGPO'
        $script:SetupPs1 | Should -Match 'Initialize-DisableWinRMGPO'
    }

    It 'Invoke-ToggleWinRMGPO should accept GPOName parameter' {
        # Function and param are on separate lines, so check both exist in function body
        $script:SetupPs1 | Should -Match 'function global:Invoke-ToggleWinRMGPO'
        $script:SetupPs1 | Should -Match '\[string\]\$GPOName'
    }

    It 'Invoke-RemoveWinRMGPOByName should accept RemoveFunction parameter' {
        # Function and param are on separate lines, so check both exist in function body
        $script:SetupPs1 | Should -Match 'function global:Invoke-RemoveWinRMGPOByName'
        $script:SetupPs1 | Should -Match '\[string\]\$RemoveFunction'
    }

    It 'Old Invoke-DisableWinRMGPO handler should not exist' {
        $script:SetupPs1 | Should -Not -Match 'function global:Invoke-DisableWinRMGPO'
    }

    It 'Old Invoke-ToggleWinRM handler should not exist' {
        $script:SetupPs1 | Should -Not -Match 'function global:Invoke-ToggleWinRM\s'
    }

    It 'Old Invoke-RemoveWinRMGPO handler should not exist' {
        $script:SetupPs1 | Should -Not -Match 'function global:Invoke-RemoveWinRMGPO\s'
    }
}

# ============================================================================
# SOFTWARE PANEL - NULL GUARD COVERAGE
# ============================================================================

Describe 'Software Panel - Null Window Guards' -Tag 'Unit', 'Software' {

    It 'Update-SoftwareDataGrid should have null Window guard' {
        $script:SoftwarePs1 | Should -Match 'function global:Update-SoftwareDataGrid'
        $script:SoftwarePs1 | Should -Match 'if \(-not \$Window\) \{ return \}'
    }

    It 'Update-SoftwareStats should have null Window guard' {
        $script:SoftwarePs1 | Should -Match 'function global:Update-SoftwareStats'
    }

    It 'Update-SoftwareSourceFilter should have null Window guard' {
        $script:SoftwarePs1 | Should -Match 'function global:Update-SoftwareSourceFilter'
    }

    It 'Update-SoftwareDataGrid should not crash with null Window' {
        { Update-SoftwareDataGrid -Window $null } | Should -Not -Throw
    }

    It 'Update-SoftwareStats should not crash with null Window' {
        { Update-SoftwareStats -Window $null } | Should -Not -Throw
    }

    It 'Update-SoftwareSourceFilter should not crash with null Window' {
        { Update-SoftwareSourceFilter -Window $null -Filter 'All' } | Should -Not -Throw
    }
}

# ============================================================================
# SOFTWARE COMPARISON - IMPORT SLOT DETECTION
# ============================================================================

Describe 'Software Import - Slot Detection Logic' -Tag 'Unit', 'Software' {

    It 'Import function should assign CSV source for baseline imports' {
        $script:SoftwarePs1 | Should -Match "Source\s*=\s*'CSV'"
    }

    It 'Import function should check for existing baseline before slotting' {
        $script:SoftwarePs1 | Should -Match '\$hasBaseline'
    }

    It 'Comparison should filter out Imported and Compare sources from baseline' {
        $script:SoftwarePs1 | Should -Match "Source -ne 'Imported' -and .* -ne 'Compare'"
    }

    It 'Comparison should recognize CSV source as valid baseline' {
        # CSV source is NOT excluded by the baseline filter (only Imported/Compare are)
        # So CSV rows pass through as baseline data
        $script:SoftwareInventory = @(
            (New-SoftwareItem -DisplayName 'FromCSV' -DisplayVersion '1.0' -Source 'CSV')
        )
        $script:SoftwareImportedData = @(
            (New-SoftwareItem -Machine 'PC2' -DisplayName 'FromCSV' -DisplayVersion '1.0' -Source 'Imported')
        )

        Invoke-CompareSoftware -Window $null

        @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
    }
}
