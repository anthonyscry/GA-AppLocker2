#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for Software Inventory comparison, CSV import flow, source filtering,
    XAML structure integrity, and module export verification.

.DESCRIPTION
    Tests the v1.2.28+ changes:
    - Software comparison engine (Match, Version Diff, Only in Scan, Only in Import)
    - Two-CSV import flow (first = baseline, second = comparison)
    - Source filter logic
    - XAML element integrity (new elements exist, old elements removed)
    - Edge cases: null data, empty data, case sensitivity, large datasets, duplicates

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Unit\SoftwareComparison.Tests.ps1 -Output Detailed
#>

BeforeAll {
    # Import the main module for core functions (Write-AppLockerLog, etc.)
    Get-Module 'GA-AppLocker*' | Remove-Module -Force -ErrorAction SilentlyContinue
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # Define UI stubs that Software.ps1 depends on (these are normally in GUI helpers)
    function global:Show-Toast { param($Message, $Type) }
    function global:Show-LoadingOverlay { param($Message, $SubMessage) }
    function global:Hide-LoadingOverlay { }
    function global:Invoke-ButtonAction { param($Action) }
    function global:Invoke-UIUpdate { param($Action) }

    # Dot-source the Software panel to get global: comparison functions
    $softwarePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\Panels\Software.ps1'
    . $softwarePath

    # Load XAML content for structure tests
    $script:XamlContent = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml') -Raw

    # Helper to build software objects
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
    # Cleanup global stubs
    Remove-Item Function:\Show-Toast -ErrorAction SilentlyContinue
    Remove-Item Function:\Show-LoadingOverlay -ErrorAction SilentlyContinue
    Remove-Item Function:\Hide-LoadingOverlay -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-ButtonAction -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-UIUpdate -ErrorAction SilentlyContinue
}

# ============================================================================
# XAML STRUCTURE INTEGRITY
# ============================================================================

Describe 'XAML Structure - Software Panel' -Tag 'Unit', 'XAML', 'Software' {

    Context 'Software DataGrid exists' {
        It 'Should have SoftwareDataGrid element' {
            $script:XamlContent | Should -Match 'x:Name="SoftwareDataGrid"'
        }
    }

    Context 'Source filter buttons exist' {
        It 'Should have BtnFilterSoftwareAll' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareAll"'
        }
        It 'Should have BtnFilterSoftwareMatch' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareMatch"'
        }
        It 'Should have BtnFilterSoftwareVersionDiff' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareVersionDiff"'
        }
        It 'Should have BtnFilterSoftwareOnlyScan' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareOnlyScan"'
        }
        It 'Should have BtnFilterSoftwareOnlyImport' {
            $script:XamlContent | Should -Match 'x:Name="BtnFilterSoftwareOnlyImport"'
        }
    }

    Context 'DataGrid has comparison row styling' {
        It 'Should have RowStyle with DataTrigger for Version Diff' {
            $script:XamlContent | Should -Match 'Binding="\{Binding Source\}".*Value="Version Diff"'
        }
        It 'Should have RowStyle with DataTrigger for Match' {
            $script:XamlContent | Should -Match 'Binding="\{Binding Source\}".*Value="Match"'
        }
        It 'Should have RowStyle with DataTrigger for Only in Scan' {
            $script:XamlContent | Should -Match 'Binding="\{Binding Source\}".*Value="Only in Scan"'
        }
        It 'Should have RowStyle with DataTrigger for Only in Import' {
            $script:XamlContent | Should -Match 'Binding="\{Binding Source\}".*Value="Only in Import"'
        }
    }
}

Describe 'XAML Structure - Setup Panel WinRM Redesign' -Tag 'Unit', 'XAML', 'Setup' {

    Context 'New per-GPO elements exist' {
        It 'Should have BtnInitializeWinRM' {
            $script:XamlContent | Should -Match 'x:Name="BtnInitializeWinRM"'
        }
        It 'Should have TxtEnableWinRMStatus' {
            $script:XamlContent | Should -Match 'x:Name="TxtEnableWinRMStatus"'
        }
        It 'Should have BtnToggleEnableWinRM' {
            $script:XamlContent | Should -Match 'x:Name="BtnToggleEnableWinRM"'
        }
        It 'Should have BtnRemoveEnableWinRM' {
            $script:XamlContent | Should -Match 'x:Name="BtnRemoveEnableWinRM"'
        }
        It 'Should have TxtDisableWinRMStatus' {
            $script:XamlContent | Should -Match 'x:Name="TxtDisableWinRMStatus"'
        }
        It 'Should have BtnToggleDisableWinRM' {
            $script:XamlContent | Should -Match 'x:Name="BtnToggleDisableWinRM"'
        }
        It 'Should have BtnRemoveDisableWinRM' {
            $script:XamlContent | Should -Match 'x:Name="BtnRemoveDisableWinRM"'
        }
    }

    Context 'Old WinRM elements removed' {
        It 'Should NOT have TxtWinRMStatus' {
            $script:XamlContent | Should -Not -Match 'x:Name="TxtWinRMStatus"'
        }
        It 'Should NOT have BtnToggleWinRM' {
            $script:XamlContent | Should -Not -Match 'x:Name="BtnToggleWinRM"'
        }
        It 'Should NOT have BtnRemoveWinRM' {
            $script:XamlContent | Should -Not -Match 'x:Name="BtnRemoveWinRM"'
        }
        It 'Should NOT have BtnDisableWinRMGPO' {
            $script:XamlContent | Should -Not -Match 'x:Name="BtnDisableWinRMGPO"'
        }
    }

    Context 'Full Initialization card layout' {
        It 'Setup panel inner grid should have no star-sized rows' {
            $match = [regex]::Match($script:XamlContent, '(?s)PanelSetup.*?<ScrollViewer.*?<Grid>(.*?)</Grid>\s*</ScrollViewer>')
            $match.Success | Should -BeTrue
            $innerGrid = $match.Groups[1].Value
            $starRows = [regex]::Matches($innerGrid, 'RowDefinition\s+Height="\*"')
            $starRows.Count | Should -Be 0
        }
    }
}

Describe 'XAML Structure - Button Order' -Tag 'Unit', 'XAML' {

    It 'Deploy: Import Policy should appear before Export Policy' {
        $importPos = $script:XamlContent.IndexOf('BtnImportPolicyXml')
        $exportPos = $script:XamlContent.IndexOf('BtnExportPolicyXml')
        $importPos | Should -BeLessThan $exportPos
    }

    It 'Software: Import CSV should appear before Export CSV' {
        $importPos = $script:XamlContent.IndexOf('BtnImportSoftwareCsv')
        $exportPos = $script:XamlContent.IndexOf('BtnExportSoftwareCsv')
        $importPos | Should -BeLessThan $exportPos
    }
}

# ============================================================================
# SOFTWARE COMPARISON ENGINE
# ============================================================================

Describe 'Software Comparison - Basic Matching' -Tag 'Unit', 'Software', 'Comparison' {

    BeforeEach {
        $script:SoftwareInventory = @()
        $script:SoftwareImportedData = @()
        $script:SoftwareImportedFile = ''
        $script:CurrentSoftwareSourceFilter = 'All'
    }

    Context 'Match detection - identical software' {
        It 'Should produce Match rows for software with same name and version' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'Notepad++' -DisplayVersion '8.6.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'Python 3.12' -DisplayVersion '3.12.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'Notepad++' -DisplayVersion '8.6.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'Python 3.12' -DisplayVersion '3.12.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $matches = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' })
            $matches.Count | Should -Be 2
        }

        It 'Should show original version in Match rows (not arrow format)' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'Git' -DisplayVersion '2.43.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'Git' -DisplayVersion '2.43.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $match = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' })
            $match.Count | Should -Be 1
            $match[0].DisplayVersion | Should -Be '2.43.0'
            $match[0].DisplayVersion | Should -Not -Match '->'
        }
    }

    Context 'Version Diff detection' {
        It 'Should produce Version Diff rows for same name, different version' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'Chrome' -DisplayVersion '120.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'Chrome' -DisplayVersion '121.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $diffs = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Version Diff' })
            $diffs.Count | Should -Be 1
            $diffs[0].DisplayVersion | Should -Be '120.0 -> 121.0'
        }

        It 'Should show Machine as "X vs Y" for version diffs' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -Machine 'SERVER1' -DisplayName 'App' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'SERVER2' -DisplayName 'App' -DisplayVersion '2.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $diff = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Version Diff' })
            $diff[0].Machine | Should -Be 'SERVER1 vs SERVER2'
        }
    }

    Context 'Only in Scan / Only in Import detection' {
        It 'Should detect software only in baseline' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'OnlyInBaseline' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'SharedApp' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'SharedApp' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $onlyScan = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Only in Scan' })
            $onlyScan.Count | Should -Be 1
            $onlyScan[0].DisplayName | Should -Be 'OnlyInBaseline'
        }

        It 'Should detect software only in import' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'SharedApp' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'SharedApp' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'OnlyInImport' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $onlyImport = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Only in Import' })
            $onlyImport.Count | Should -Be 1
            $onlyImport[0].DisplayName | Should -Be 'OnlyInImport'
        }
    }

    Context 'Mixed results - all four categories' {
        It 'Should correctly categorize a mixed set' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'MatchApp' -DisplayVersion '1.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'DiffApp' -DisplayVersion '1.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'ScanOnly' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'MatchApp' -DisplayVersion '1.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'DiffApp' -DisplayVersion '2.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'ImportOnly' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $results = $script:SoftwareInventory
            @($results | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
            @($results | Where-Object { $_.Source -eq 'Version Diff' }).Count | Should -Be 1
            @($results | Where-Object { $_.Source -eq 'Only in Scan' }).Count | Should -Be 1
            @($results | Where-Object { $_.Source -eq 'Only in Import' }).Count | Should -Be 1
            $results.Count | Should -Be 4
        }

        It 'Should sort results: Version Diff first, Match last' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'MatchApp' -DisplayVersion '1.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'DiffApp' -DisplayVersion '1.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'ScanOnly' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'MatchApp' -DisplayVersion '1.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'DiffApp' -DisplayVersion '2.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'ImportOnly' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $results = $script:SoftwareInventory
            $results[0].Source | Should -Be 'Version Diff'
            $results[-1].Source | Should -Be 'Match'
        }
    }
}

# ============================================================================
# TWO-CSV IMPORT FLOW
# ============================================================================

Describe 'Software Comparison - CSV Baseline Source' -Tag 'Unit', 'Software', 'Comparison' {

    BeforeEach {
        $script:SoftwareInventory = @()
        $script:SoftwareImportedData = @()
        $script:SoftwareImportedFile = ''
        $script:CurrentSoftwareSourceFilter = 'All'
    }

    Context 'CSV source treated as baseline' {
        It 'Should compare CSV baseline against imported data' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'AppA' -DisplayVersion '1.0' -Source 'CSV'),
                (New-SoftwareItem -DisplayName 'AppB' -DisplayVersion '2.0' -Source 'CSV')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'AppA' -DisplayVersion '1.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'AppB' -DisplayVersion '3.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'AppC' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $results = $script:SoftwareInventory
            @($results | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
            @($results | Where-Object { $_.Source -eq 'Version Diff' }).Count | Should -Be 1
            @($results | Where-Object { $_.Source -eq 'Only in Import' }).Count | Should -Be 1
            @($results | Where-Object { $_.Source -eq 'Only in Scan' }).Count | Should -Be 0
        }

        It 'Should exclude prior comparison results from baseline' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'RealApp' -DisplayVersion '1.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'OldCompare' -DisplayVersion '1.0' -Source 'Compare'),
                (New-SoftwareItem -DisplayName 'OldImported' -DisplayVersion '1.0' -Source 'Imported')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'RealApp' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $matches = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' })
            $matches.Count | Should -Be 1
            $matches[0].DisplayName | Should -Be 'RealApp'
        }
    }
}

# ============================================================================
# EDGE CASES
# ============================================================================

Describe 'Software Comparison - Edge Cases' -Tag 'Unit', 'Software', 'EdgeCase' {

    BeforeEach {
        $script:SoftwareInventory = @()
        $script:SoftwareImportedData = @()
        $script:SoftwareImportedFile = ''
        $script:CurrentSoftwareSourceFilter = 'All'
    }

    Context 'Empty data guards' {
        It 'Should not crash when no imported data exists' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'App' -Source 'Local')
            )
            $script:SoftwareImportedData = @()
            { Invoke-CompareSoftware -Window $null } | Should -Not -Throw
        }

        It 'Should not crash when no baseline data exists' {
            $script:SoftwareInventory = @()
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App' -Source 'Imported')
            )
            { Invoke-CompareSoftware -Window $null } | Should -Not -Throw
        }

        It 'Should not crash when both datasets are empty' {
            $script:SoftwareInventory = @()
            $script:SoftwareImportedData = @()
            { Invoke-CompareSoftware -Window $null } | Should -Not -Throw
        }
    }

    Context 'Case-insensitive matching' {
        It 'Should match "Notepad++" and "notepad++" as the same software' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'Notepad++' -DisplayVersion '8.6' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'notepad++' -DisplayVersion '8.6' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $matches = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' })
            $matches.Count | Should -Be 1
        }

        It 'Should match mixed case as version diff (not two separate entries)' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'CHROME' -DisplayVersion '120' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'chrome' -DisplayVersion '121' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Version Diff' }).Count | Should -Be 1
            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Only in Scan' }).Count | Should -Be 0
            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Only in Import' }).Count | Should -Be 0
        }
    }

    Context 'Whitespace handling' {
        It 'Should treat trimmed versions as equal' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'App' -DisplayVersion '1.0.0 ' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App' -DisplayVersion ' 1.0.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
        }

        It 'Should treat trimmed names as equal' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'App Name  ' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName '  App Name' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
        }
    }

    Context 'Null and empty version handling' {
        It 'Should treat two empty versions as Match' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'NoVersionApp' -DisplayVersion '' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'NoVersionApp' -DisplayVersion '' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Version Diff' }).Count | Should -Be 0
        }

        It 'Should detect version diff when one has version and other does not' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'App' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App' -DisplayVersion '' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $diffs = @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Version Diff' })
            $diffs.Count | Should -Be 1
            $diffs[0].DisplayVersion | Should -Be '1.0 -> '
        }
    }

    Context 'Duplicate names in same dataset' {
        It 'Should use first occurrence when duplicates exist in baseline' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'DupeApp' -DisplayVersion '1.0' -Publisher 'First' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'DupeApp' -DisplayVersion '2.0' -Publisher 'Second' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'DupeApp' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 1
        }
    }

    Context '100% match scenario' {
        It 'Should produce all Match rows when inventories are identical' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'App1' -DisplayVersion '1.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'App2' -DisplayVersion '2.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'App3' -DisplayVersion '3.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App1' -DisplayVersion '1.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App2' -DisplayVersion '2.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'App3' -DisplayVersion '3.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $results = $script:SoftwareInventory
            $results.Count | Should -Be 3
            @($results | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 3
        }
    }

    Context '0% match scenario' {
        It 'Should produce only Scan and Import rows when nothing overlaps' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'ScanApp1' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'ScanApp2' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'ImportApp1' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'ImportApp2' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            $results = $script:SoftwareInventory
            $results.Count | Should -Be 4
            @($results | Where-Object { $_.Source -eq 'Only in Scan' }).Count | Should -Be 2
            @($results | Where-Object { $_.Source -eq 'Only in Import' }).Count | Should -Be 2
            @($results | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 0
        }
    }

    Context 'Large dataset performance' {
        It 'Should handle 500 items per side without error' {
            $script:SoftwareInventory = @(1..500 | ForEach-Object {
                New-SoftwareItem -DisplayName "App_$_" -DisplayVersion "$_.0" -Source 'Local'
            })
            $script:SoftwareImportedData = @(
                @(1..250 | ForEach-Object {
                    $ver = if ($_ % 2 -eq 0) { "$_.0" } else { "$_.1" }
                    New-SoftwareItem -Machine 'PC2' -DisplayName "App_$_" -DisplayVersion $ver -Source 'Imported'
                })
                @(501..750 | ForEach-Object {
                    New-SoftwareItem -Machine 'PC2' -DisplayName "ImportApp_$_" -DisplayVersion '1.0' -Source 'Imported'
                })
            )

            { Invoke-CompareSoftware -Window $null } | Should -Not -Throw

            $results = $script:SoftwareInventory
            $results.Count | Should -BeGreaterThan 0
            @($results | Where-Object { $_.Source -eq 'Only in Scan' }).Count | Should -Be 250
            @($results | Where-Object { $_.Source -eq 'Only in Import' }).Count | Should -Be 250
            @($results | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 125
            @($results | Where-Object { $_.Source -eq 'Version Diff' }).Count | Should -Be 125
        }
    }

    Context 'Special characters in software names' {
        It 'Should match names with parentheses, dots, and symbols' {
            $script:SoftwareInventory = @(
                (New-SoftwareItem -DisplayName 'Microsoft Visual C++ 2019 (x64)' -DisplayVersion '14.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'Node.js v18.19.0' -DisplayVersion '18.19.0' -Source 'Local'),
                (New-SoftwareItem -DisplayName 'C:\Program Files\App' -DisplayVersion '1.0' -Source 'Local')
            )
            $script:SoftwareImportedData = @(
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'Microsoft Visual C++ 2019 (x64)' -DisplayVersion '14.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'Node.js v18.19.0' -DisplayVersion '20.0.0' -Source 'Imported'),
                (New-SoftwareItem -Machine 'PC2' -DisplayName 'C:\Program Files\App' -DisplayVersion '1.0' -Source 'Imported')
            )

            Invoke-CompareSoftware -Window $null

            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Match' }).Count | Should -Be 2
            @($script:SoftwareInventory | Where-Object { $_.Source -eq 'Version Diff' }).Count | Should -Be 1
        }
    }
}

# ============================================================================
# SOURCE FILTER LOGIC
# ============================================================================

Describe 'Software Source Filter' -Tag 'Unit', 'Software', 'Filter' {

    BeforeEach {
        $script:SoftwareInventory = @(
            (New-SoftwareItem -DisplayName 'MatchApp' -Source 'Match'),
            (New-SoftwareItem -DisplayName 'DiffApp' -Source 'Version Diff'),
            (New-SoftwareItem -DisplayName 'ScanApp' -Source 'Only in Scan'),
            (New-SoftwareItem -DisplayName 'ImportApp' -Source 'Only in Import')
        )
        $script:CurrentSoftwareSourceFilter = 'All'
    }

    Context 'Filter state management' {
        It 'Should default to All filter' {
            $script:CurrentSoftwareSourceFilter | Should -Be 'All'
        }

        It 'Should update filter state to Match' {
            Update-SoftwareSourceFilter -Window $null -Filter 'Match'
            $script:CurrentSoftwareSourceFilter | Should -Be 'Match'
        }

        It 'Should map VersionDiff tag to "Version Diff" source value' {
            Update-SoftwareSourceFilter -Window $null -Filter 'VersionDiff'
            $script:CurrentSoftwareSourceFilter | Should -Be 'Version Diff'
        }

        It 'Should map OnlyScan tag to "Only in Scan" source value' {
            Update-SoftwareSourceFilter -Window $null -Filter 'OnlyScan'
            $script:CurrentSoftwareSourceFilter | Should -Be 'Only in Scan'
        }

        It 'Should map OnlyImport tag to "Only in Import" source value' {
            Update-SoftwareSourceFilter -Window $null -Filter 'OnlyImport'
            $script:CurrentSoftwareSourceFilter | Should -Be 'Only in Import'
        }

        It 'Should default unknown filter to All' {
            Update-SoftwareSourceFilter -Window $null -Filter 'Bogus'
            $script:CurrentSoftwareSourceFilter | Should -Be 'All'
        }
    }

    Context 'DataGrid filtering by source does not crash with null Window' {
        It 'All filter should not crash' {
            $script:CurrentSoftwareSourceFilter = 'All'
            { Update-SoftwareDataGrid -Window $null } | Should -Not -Throw
        }

        It 'Match filter should not crash' {
            $script:CurrentSoftwareSourceFilter = 'Match'
            { Update-SoftwareDataGrid -Window $null } | Should -Not -Throw
        }

        It 'Version Diff filter should not crash' {
            $script:CurrentSoftwareSourceFilter = 'Version Diff'
            { Update-SoftwareDataGrid -Window $null } | Should -Not -Throw
        }
    }
}

# ============================================================================
# MODULE EXPORTS VERIFICATION
# ============================================================================

Describe 'Module Exports - Setup Functions' -Tag 'Unit', 'Module', 'Exports' {

    It 'Should export Initialize-WinRMGPO' {
        Get-Command 'Initialize-WinRMGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Enable-WinRMGPO' {
        Get-Command 'Enable-WinRMGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Disable-WinRMGPO' {
        Get-Command 'Disable-WinRMGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Remove-WinRMGPO' {
        Get-Command 'Remove-WinRMGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Initialize-DisableWinRMGPO' {
        Get-Command 'Initialize-DisableWinRMGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Remove-DisableWinRMGPO' {
        Get-Command 'Remove-DisableWinRMGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Get-SetupStatus' {
        Get-Command 'Get-SetupStatus' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Initialize-AppLockerEnvironment' {
        Get-Command 'Initialize-AppLockerEnvironment' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Initialize-AppLockerGPOs' {
        Get-Command 'Initialize-AppLockerGPOs' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Initialize-ADStructure' {
        Get-Command 'Initialize-ADStructure' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'Module Exports - Core Functions' -Tag 'Unit', 'Module', 'Exports' {

    It 'Should export Write-AppLockerLog' {
        Get-Command 'Write-AppLockerLog' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Get-AppLockerConfig' {
        Get-Command 'Get-AppLockerConfig' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export New-HashRule' {
        Get-Command 'New-HashRule' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export New-PublisherRule' {
        Get-Command 'New-PublisherRule' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export New-Policy' {
        Get-Command 'New-Policy' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Export-PolicyToXml' {
        Get-Command 'Export-PolicyToXml' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Import-RulesFromXml' {
        Get-Command 'Import-RulesFromXml' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Get-RuleById' {
        Get-Command 'Get-RuleById' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Save-RuleToRepository' {
        Get-Command 'Save-RuleToRepository' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}
