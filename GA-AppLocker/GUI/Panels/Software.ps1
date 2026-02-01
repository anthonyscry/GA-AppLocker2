#region Software Inventory Panel Functions
# Software.ps1 - Installed software scanning, CSV export/import, and cross-system comparison

# Script-level state for this panel
$script:SoftwareInventory = @()       # Current scan/imported data shown in DataGrid
$script:SoftwareImportedData = @()    # Imported CSV data for comparison
$script:SoftwareImportedFile = ''     # Name of imported file
$script:CurrentSoftwareSourceFilter = 'All'  # Source filter for comparison results

function Initialize-SoftwarePanel {
    param([System.Windows.Window]$Window)

    # Wire up sidebar buttons via Tag -> Invoke-ButtonAction
    $buttons = @(
        'BtnScanLocalSoftware', 'BtnScanRemoteSoftware',
        'BtnExportSoftwareCsv', 'BtnImportSoftwareCsv',
        'BtnCompareSoftware', 'BtnClearComparison'
    )
    foreach ($btnName in $buttons) {
        $btn = $Window.FindName($btnName)
        if ($btn -and $btn.Tag) {
            $tagValue = $btn.Tag.ToString()
            $btn.Add_Click({ Invoke-ButtonAction -Action $tagValue }.GetNewClosure())
        }
    }

    # Wire up source filter buttons
    $sourceFilterButtons = @(
        'BtnFilterSoftwareAll', 'BtnFilterSoftwareMatch', 'BtnFilterSoftwareVersionDiff',
        'BtnFilterSoftwareOnlyScan', 'BtnFilterSoftwareOnlyImport'
    )
    foreach ($btnName in $sourceFilterButtons) {
        $btn = $Window.FindName($btnName)
        if ($btn) {
            $btn.Add_Click({
                param($sender, $e)
                $tag = $sender.Tag
                if ($tag -match 'FilterSoftware(.+)') {
                    $filter = $Matches[1]
                    Update-SoftwareSourceFilter -Window $global:GA_MainWindow -Filter $filter
                }
            }.GetNewClosure())
        }
    }

    # Wire up text filter with debounce
    $filterBox = $Window.FindName('TxtSoftwareFilter')
    if ($filterBox) {
        $filterBox.Add_TextChanged({
            Update-SoftwareDataGrid -Window $global:GA_MainWindow
        })
    }

    # Wire up remote machine textbox to show live count
    $remoteMachineBox = $Window.FindName('TxtSoftwareRemoteMachines')
    if ($remoteMachineBox) {
        $remoteMachineBox.Add_TextChanged({
            $machineBox = $global:GA_MainWindow.FindName('TxtSoftwareRemoteMachines')
            $hint = $global:GA_MainWindow.FindName('TxtSoftwareMachineHint')
            if ($machineBox -and $hint) {
                $parsed = @(Get-SoftwareRemoteMachineList -Window $global:GA_MainWindow)
                if ($parsed.Count -gt 0) {
                    $hint.Text = "$($parsed.Count) machine(s): $($parsed[0..2] -join ', ')$(if ($parsed.Count -gt 3) { '...' })"
                } else {
                    $scanCount = @($script:SelectedScanMachines).Count
                    if ($scanCount -gt 0) {
                        $hint.Text = "Empty -- will use Scanner list ($scanCount machines)"
                    } else {
                        $hint.Text = '0 machines'
                    }
                }
            }
        })
    }
}

#region ===== SCAN FUNCTIONS =====

function script:Get-SoftwareRemoteMachineList {
    <#
    .SYNOPSIS
        Parses the remote machine textbox into a list of hostnames.
        Falls back to $script:SelectedScanMachines (Scanner panel list) if textbox is empty.
    #>
    param([System.Windows.Window]$Window)

    $machineBox = $Window.FindName('TxtSoftwareRemoteMachines')
    $rawText = if ($machineBox) { $machineBox.Text } else { '' }

    if (-not [string]::IsNullOrWhiteSpace($rawText)) {
        # Parse: split by newlines, commas, semicolons, then trim and deduplicate
        $parsed = @($rawText -split '[,;\r\n]+' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' } |
            Sort-Object -Unique)
        return $parsed
    }

    # Fallback: Scanner panel machine list
    $scanMachines = @($script:SelectedScanMachines)
    if ($scanMachines.Count -gt 0) {
        $hostnames = @($scanMachines | ForEach-Object {
            if ($_ -is [string]) { $_ } else { $_.Hostname }
        })
        return $hostnames
    }

    return @()
}

function global:Invoke-ScanLocalSoftware {
    <#
    .SYNOPSIS
        Scans installed software on the local machine via registry.
    #>
    param([System.Windows.Window]$Window)

    Show-LoadingOverlay -Message 'Scanning installed software...' -SubMessage $env:COMPUTERNAME

    try {
        $results = Get-InstalledSoftware -MachineName $env:COMPUTERNAME
        $script:SoftwareInventory = $results

        Update-SoftwareDataGrid -Window $Window
        Update-SoftwareStats -Window $Window

        $statusText = $Window.FindName('TxtSoftwareStatus')
        if ($statusText) { $statusText.Text = "Scanned $($results.Count) programs on $env:COMPUTERNAME" }

        $lastScan = $Window.FindName('TxtSoftwareLastScan')
        if ($lastScan) { $lastScan.Text = "$env:COMPUTERNAME - $(Get-Date -Format 'MM/dd HH:mm')" }

        # Auto-save local scan CSV: hostname_softwarelist_ddMMMYY.csv
        try {
            $appDataPath = Get-AppLockerDataPath
            $scansFolder = [System.IO.Path]::Combine($appDataPath, 'Scans')
            if (-not [System.IO.Directory]::Exists($scansFolder)) {
                [System.IO.Directory]::CreateDirectory($scansFolder) | Out-Null
            }
            $dateSuffix = (Get-Date).ToString('ddMMMyy').ToUpper()
            $csvName = "$($env:COMPUTERNAME)_softwarelist_${dateSuffix}.csv"
            $csvPath = [System.IO.Path]::Combine($scansFolder, $csvName)
            $results |
                Select-Object Machine, DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, Architecture, Source |
                Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-AppLockerLog -Message "Auto-saved software list: $csvName" -Level 'INFO'
        } catch {
            Write-AppLockerLog -Message "Failed to auto-save local CSV: $($_.Exception.Message)" -Level 'ERROR'
        }

        Show-Toast -Message "Found $($results.Count) installed programs on local machine. CSV saved to Scans folder." -Type 'Success'
    }
    catch {
        Write-AppLockerLog -Message "Local software scan failed: $($_.Exception.Message)" -Level 'ERROR'
        Show-Toast -Message "Scan failed: $($_.Exception.Message)" -Type 'Error'
    }
    finally {
        Hide-LoadingOverlay
    }
}

function global:Invoke-ScanRemoteSoftware {
    <#
    .SYNOPSIS
        Scans installed software on remote machines via WinRM (background runspace).
    #>
    param([System.Windows.Window]$Window)

    $hostnames = @(Get-SoftwareRemoteMachineList -Window $Window)
    if ($hostnames.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "No remote machines specified.`n`nTo add machines:`n1. Go to AD Discovery and run a connectivity test`n2. Navigate to Software Inventory -- online machines with WinRM will auto-populate`n3. Or type hostnames directly in the Remote Machines box (one per line)",
            'No Machines Selected', 'OK', 'Warning')
        return
    }

    Show-LoadingOverlay -Message "Scanning software on $($hostnames.Count) machine(s)..." -SubMessage ($hostnames[0..2] -join ', ')

    # Get credential on UI thread (needs access to DPAPI)
    $cred = $null
    foreach ($tryTier in @(2, 1, 0)) {
        try {
            $credResult = Get-CredentialForTier -Tier $tryTier
            if ($credResult.Success -and $credResult.Data) {
                $cred = $credResult.Data
                break
            }
        } catch { }
    }

    # Build synchronized hashtable for cross-thread communication
    $script:SoftwareSyncHash = [hashtable]::Synchronized(@{
        Window     = $Window
        Hostnames  = $hostnames
        Credential = $cred
        Result     = $null
        Error      = $null
        IsComplete = $false
        StatusText = 'Initializing...'
    })

    # Create background runspace
    $script:SoftwareRunspace = [runspacefactory]::CreateRunspace()
    $script:SoftwareRunspace.ApartmentState = 'STA'
    $script:SoftwareRunspace.ThreadOptions = 'ReuseThread'
    $script:SoftwareRunspace.Open()
    $script:SoftwareRunspace.SessionStateProxy.SetVariable('SyncHash', $script:SoftwareSyncHash)

    $modulePath = (Get-Module GA-AppLocker).ModuleBase
    $script:SoftwareRunspace.SessionStateProxy.SetVariable('ModulePath', $modulePath)

    $script:SoftwarePowerShell = [powershell]::Create()
    $script:SoftwarePowerShell.Runspace = $script:SoftwareRunspace

    [void]$script:SoftwarePowerShell.AddScript({
        param($SyncHash, $ModulePath)

        try {
            # Import module in this runspace
            $manifestPath = Join-Path $ModulePath 'GA-AppLocker.psd1'
            if (Test-Path $manifestPath) {
                Import-Module $manifestPath -Force -ErrorAction Stop
            }

            $hostnames = $SyncHash.Hostnames
            $cred = $SyncHash.Credential
            $allResults = [System.Collections.Generic.List[PSCustomObject]]::new()
            $failedHosts = [System.Collections.Generic.List[string]]::new()

            # Ensure Scans folder exists
            $scansFolder = $null
            try {
                $appDataPath = Get-AppLockerDataPath
                $scansFolder = [System.IO.Path]::Combine($appDataPath, 'Scans')
                if (-not [System.IO.Directory]::Exists($scansFolder)) {
                    [System.IO.Directory]::CreateDirectory($scansFolder) | Out-Null
                }
            } catch { }

            $dateSuffix = (Get-Date).ToString('ddMMMyy').ToUpper()
            $hostIndex = 0

            foreach ($hostname in $hostnames) {
                $hostIndex++
                $SyncHash.StatusText = "Scanning $hostname ($hostIndex/$($hostnames.Count))..."

                try {
                    $invokeParams = @{
                        ComputerName = $hostname
                        ScriptBlock  = {
                            $paths = @(
                                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
                            )
                            Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
                                Where-Object { $_.DisplayName -and $_.DisplayName.Trim() -ne '' } |
                                ForEach-Object {
                                    [PSCustomObject]@{
                                        DisplayName     = $_.DisplayName
                                        DisplayVersion  = $_.DisplayVersion
                                        Publisher        = $_.Publisher
                                        InstallDate      = $_.InstallDate
                                        InstallLocation  = $_.InstallLocation
                                        Architecture     = if ($_.PSPath -like '*WOW6432*') { 'x86' } else { 'x64' }
                                    }
                                }
                        }
                        ErrorAction = 'Stop'
                    }
                    if ($cred) { $invokeParams['Credential'] = $cred }

                    $remoteResults = @(Invoke-Command @invokeParams)
                    $hostResults = [System.Collections.Generic.List[PSCustomObject]]::new()
                    foreach ($item in $remoteResults) {
                        $obj = [PSCustomObject]@{
                            Machine         = $hostname
                            DisplayName     = $item.DisplayName
                            DisplayVersion  = $item.DisplayVersion
                            Publisher        = $item.Publisher
                            InstallDate      = $item.InstallDate
                            InstallLocation  = $item.InstallLocation
                            Architecture     = $item.Architecture
                            Source           = 'Remote'
                        }
                        $allResults.Add($obj)
                        $hostResults.Add($obj)
                    }

                    # Auto-save per-hostname CSV
                    if ($scansFolder -and $hostResults.Count -gt 0) {
                        try {
                            $csvName = "${hostname}_softwarelist_${dateSuffix}.csv"
                            $csvPath = [System.IO.Path]::Combine($scansFolder, $csvName)
                            $hostResults |
                                Select-Object Machine, DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, Architecture, Source |
                                Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                        } catch { }
                    }
                }
                catch {
                    $failedHosts.Add("${hostname}: $($_.Exception.Message)")
                }
            }

            $SyncHash.StatusText = 'Processing results...'
            $SyncHash.Result = @{
                AllResults  = @($allResults)
                FailedHosts = @($failedHosts)
                HostCount   = $hostnames.Count
                ScansFolder = $scansFolder
            }
        }
        catch {
            $SyncHash.Error = $_.Exception.Message
        }
        finally {
            $SyncHash.IsComplete = $true
        }
    })

    [void]$script:SoftwarePowerShell.AddArgument($script:SoftwareSyncHash)
    [void]$script:SoftwarePowerShell.AddArgument($modulePath)

    # Start async
    $script:SoftwareAsyncResult = $script:SoftwarePowerShell.BeginInvoke()

    # Poll for completion via DispatcherTimer
    $script:SoftwareTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:SoftwareTimer.Interval = [TimeSpan]::FromMilliseconds(300)

    $script:SoftwareTimer.Add_Tick({
        $syncHash = $script:SoftwareSyncHash
        $win = $syncHash.Window

        # Update overlay text
        Show-LoadingOverlay -Message $syncHash.StatusText

        if ($syncHash.IsComplete) {
            $script:SoftwareTimer.Stop()

            try { $script:SoftwarePowerShell.EndInvoke($script:SoftwareAsyncResult) } catch { }
            if ($script:SoftwarePowerShell) { $script:SoftwarePowerShell.Dispose() }
            if ($script:SoftwareRunspace) {
                $script:SoftwareRunspace.Close()
                $script:SoftwareRunspace.Dispose()
            }

            Hide-LoadingOverlay

            if ($syncHash.Error) {
                Show-Toast -Message "Remote scan failed: $($syncHash.Error)" -Type 'Error'
                return
            }

            $r = $syncHash.Result
            $script:SoftwareInventory = $r.AllResults
            Update-SoftwareDataGrid -Window $win
            Update-SoftwareStats -Window $win

            $statusText = $win.FindName('TxtSoftwareStatus')
            if ($statusText) { $statusText.Text = "Scanned $($r.AllResults.Count) programs across $($r.HostCount) machine(s)" }

            $lastScan = $win.FindName('TxtSoftwareLastScan')
            if ($lastScan) { $lastScan.Text = "$($r.HostCount) machines - $(Get-Date -Format 'MM/dd HH:mm')" }

            if ($r.FailedHosts.Count -gt 0) {
                $failDetails = $r.FailedHosts -join "`n"
                [System.Windows.MessageBox]::Show(
                    "Scan completed but $($r.FailedHosts.Count) machine(s) failed:`n`n$failDetails",
                    'Partial Scan Results', 'OK', 'Warning')
            }

            $toastMsg = "Found $($r.AllResults.Count) installed programs across $($r.HostCount) machine(s)."
            if ($r.ScansFolder) { $toastMsg += " CSVs saved to Scans folder." }
            $toastType = if ($r.FailedHosts.Count -gt 0) { 'Warning' } else { 'Success' }
            Show-Toast -Message $toastMsg -Type $toastType
        }
    })

    $script:SoftwareTimer.Start()
}

function script:Get-InstalledSoftware {
    <#
    .SYNOPSIS
        Enumerates installed software from the registry (local machine).
    #>
    param([string]$MachineName = $env:COMPUTERNAME)

    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $results = @(Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.DisplayName.Trim() -ne '' } |
        ForEach-Object {
            [PSCustomObject]@{
                Machine        = $MachineName
                DisplayName    = $_.DisplayName
                DisplayVersion = if ($_.DisplayVersion) { $_.DisplayVersion } else { '' }
                Publisher      = if ($_.Publisher) { $_.Publisher } else { '' }
                InstallDate    = if ($_.InstallDate) { $_.InstallDate } else { '' }
                InstallLocation = if ($_.InstallLocation) { $_.InstallLocation } else { '' }
                Architecture   = if ($_.PSPath -like '*WOW6432*') { 'x86' } else { 'x64' }
                Source         = 'Local'
            }
        } | Sort-Object DisplayName)

    return $results
}

#endregion

#region ===== CSV EXPORT / IMPORT =====

function global:Invoke-ExportSoftwareCsv {
    <#
    .SYNOPSIS
        Exports the current software inventory DataGrid to a CSV file.
    #>
    param([System.Windows.Window]$Window)

    if ($script:SoftwareInventory.Count -eq 0) {
        Show-Toast -Message 'No software data to export. Run a scan first.' -Type 'Warning'
        return
    }

    $dialog = [Microsoft.Win32.SaveFileDialog]::new()
    $dialog.Title = 'Export Software Inventory'
    $dialog.Filter = 'CSV Files (*.csv)|*.csv|All Files (*.*)|*.*'
    $dialog.DefaultExt = '.csv'

    # Default filename with machine name and date
    $machines = @($script:SoftwareInventory | ForEach-Object { $_.Machine } | Sort-Object -Unique)
    $machineLabel = if ($machines.Count -eq 1) { $machines[0] } else { "$($machines.Count)-machines" }
    $dialog.FileName = "SoftwareInventory_${machineLabel}_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"

    $result = $dialog.ShowDialog($Window)
    if (-not $result) { return }

    try {
        $script:SoftwareInventory |
            Select-Object Machine, DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, Architecture, Source |
            Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8

        Show-Toast -Message "Exported $($script:SoftwareInventory.Count) items to CSV." -Type 'Success'
        Write-AppLockerLog -Message "Exported software inventory to: $($dialog.FileName)" -Level 'INFO'
    }
    catch {
        Write-AppLockerLog -Message "CSV export failed: $($_.Exception.Message)" -Level 'ERROR'
        Show-Toast -Message "Export failed: $($_.Exception.Message)" -Type 'Error'
    }
}

function global:Invoke-ImportSoftwareCsv {
    <#
    .SYNOPSIS
        Imports a software inventory CSV file for viewing or comparison.
        First import (or import when no scan/baseline exists) becomes the baseline.
        Second import goes into the comparison slot for Compare Inventories.
    #>
    param([System.Windows.Window]$Window)

    $dialog = [Microsoft.Win32.OpenFileDialog]::new()
    $dialog.Title = 'Import Software Inventory CSV'
    $dialog.Filter = 'CSV Files (*.csv)|*.csv|All Files (*.*)|*.*'

    $result = $dialog.ShowDialog($Window)
    if (-not $result) { return }

    try {
        $imported = @(Import-Csv -Path $dialog.FileName -Encoding UTF8)

        if ($imported.Count -eq 0) {
            Show-Toast -Message 'CSV file is empty.' -Type 'Warning'
            return
        }

        # Validate expected columns exist
        $firstRow = $imported[0]
        $hasDisplayName = $null -ne $firstRow.PSObject.Properties['DisplayName']
        if (-not $hasDisplayName) {
            Show-Toast -Message 'CSV missing required "DisplayName" column. Expected columns: Machine, DisplayName, DisplayVersion, Publisher, InstallDate, Architecture.' -Type 'Error'
            return
        }

        $fileName = [System.IO.Path]::GetFileName($dialog.FileName)

        # Normalize: ensure all expected properties exist
        $normalized = @($imported | ForEach-Object {
            [PSCustomObject]@{
                Machine        = if ($_.Machine) { $_.Machine } else { 'Imported' }
                DisplayName    = $_.DisplayName
                DisplayVersion = if ($_.DisplayVersion) { $_.DisplayVersion } else { '' }
                Publisher      = if ($_.Publisher) { $_.Publisher } else { '' }
                InstallDate    = if ($_.InstallDate) { $_.InstallDate } else { '' }
                InstallLocation = if ($_.InstallLocation) { $_.InstallLocation } else { '' }
                Architecture   = if ($_.Architecture) { $_.Architecture } else { '' }
                Source         = 'Imported'
            }
        })

        # Determine slot: if no baseline exists (no scan data and no prior import as baseline), this becomes the baseline.
        # If baseline already exists (from scan or prior import), this goes into the comparison slot.
        $hasBaseline = @($script:SoftwareInventory | Where-Object { $_.Source -ne 'Imported' -and $_.Source -ne 'Compare' }).Count -gt 0
        $hasBaselineFromImport = $script:SoftwareInventory.Count -gt 0 -and $script:SoftwareImportedData.Count -eq 0

        if (-not $hasBaseline -and -not $hasBaselineFromImport) {
            # No baseline — this CSV becomes the baseline (shown in DataGrid as "CSV" source)
            $baselineData = @($normalized | ForEach-Object {
                [PSCustomObject]@{
                    Machine        = $_.Machine
                    DisplayName    = $_.DisplayName
                    DisplayVersion = $_.DisplayVersion
                    Publisher      = $_.Publisher
                    InstallDate    = $_.InstallDate
                    InstallLocation = $_.InstallLocation
                    Architecture   = $_.Architecture
                    Source         = 'CSV'
                }
            })
            $script:SoftwareInventory = $baselineData
            $script:SoftwareImportedData = @()
            $script:SoftwareImportedFile = ''

            Update-SoftwareDataGrid -Window $Window
            Update-SoftwareStats -Window $Window

            $statusText = $Window.FindName('TxtSoftwareStatus')
            if ($statusText) { $statusText.Text = "Baseline: $($baselineData.Count) items from $fileName - import another CSV to compare." }

            $lastScan = $Window.FindName('TxtSoftwareLastScan')
            if ($lastScan) { $lastScan.Text = "CSV: $fileName" }

            Show-Toast -Message "Loaded $($baselineData.Count) items as baseline from $fileName. Import another CSV to compare." -Type 'Success'
            Write-AppLockerLog -Message "Imported software CSV as baseline: $($dialog.FileName) ($($baselineData.Count) items)" -Level 'INFO'
        }
        else {
            # Baseline exists — this CSV goes into comparison slot
            $script:SoftwareImportedData = $normalized
            $script:SoftwareImportedFile = $fileName

            $importedFileText = $Window.FindName('TxtSoftwareImportedFile')
            if ($importedFileText) { $importedFileText.Text = "$fileName ($($normalized.Count) items)" }

            $statusText = $Window.FindName('TxtSoftwareStatus')
            if ($statusText) { $statusText.Text = "Comparison ready: $($normalized.Count) items from $fileName. Click Compare Inventories." }

            Show-Toast -Message "Loaded $($normalized.Count) items for comparison from $fileName. Click Compare Inventories." -Type 'Success'
            Write-AppLockerLog -Message "Imported software CSV for comparison: $($dialog.FileName) ($($normalized.Count) items)" -Level 'INFO'
        }
    }
    catch {
        Write-AppLockerLog -Message "CSV import failed: $($_.Exception.Message)" -Level 'ERROR'
        Show-Toast -Message "Import failed: $($_.Exception.Message)" -Type 'Error'
    }
}

#endregion

#region ===== COMPARISON =====

function global:Invoke-CompareSoftware {
    <#
    .SYNOPSIS
        Compares baseline data (scan or first CSV) against imported CSV data.
        Shows four categories: Match, Version Diff, Only in Baseline, Only in Import.
    #>
    param([System.Windows.Window]$Window)

    # Need both a baseline and an import to compare
    if ($script:SoftwareImportedData.Count -eq 0) {
        Show-Toast -Message 'No imported data to compare against. Import a second CSV first.' -Type 'Warning'
        return
    }

    # Get baseline data (scan results or first-imported CSV, not the comparison-imported entries)
    $scanData = @($script:SoftwareInventory | Where-Object { $_.Source -ne 'Imported' -and $_.Source -ne 'Compare' })
    if ($scanData.Count -eq 0) {
        Show-Toast -Message 'No baseline data to compare. Run a scan or import a CSV first, then import a second CSV.' -Type 'Warning'
        return
    }

    Show-LoadingOverlay -Message 'Comparing software inventories...'

    try {
        $comparisonResults = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Build lookup by DisplayName (case-insensitive)
        $scanLookup = @{}
        foreach ($item in $scanData) {
            $key = $item.DisplayName.ToLower().Trim()
            if (-not $scanLookup.ContainsKey($key)) {
                $scanLookup[$key] = $item
            }
        }

        $importLookup = @{}
        foreach ($item in $script:SoftwareImportedData) {
            $key = $item.DisplayName.ToLower().Trim()
            if (-not $importLookup.ContainsKey($key)) {
                $importLookup[$key] = $item
            }
        }

        # Only in scan (not in imported)
        foreach ($key in $scanLookup.Keys) {
            if (-not $importLookup.ContainsKey($key)) {
                $s = $scanLookup[$key]
                $comparisonResults.Add([PSCustomObject]@{
                    Machine        = $s.Machine
                    DisplayName    = $s.DisplayName
                    DisplayVersion = $s.DisplayVersion
                    Publisher      = $s.Publisher
                    InstallDate    = $s.InstallDate
                    InstallLocation = $s.InstallLocation
                    Architecture   = $s.Architecture
                    Source         = 'Only in Scan'
                })
            }
        }

        # Only in imported (not in scan)
        foreach ($key in $importLookup.Keys) {
            if (-not $scanLookup.ContainsKey($key)) {
                $i = $importLookup[$key]
                $comparisonResults.Add([PSCustomObject]@{
                    Machine        = $i.Machine
                    DisplayName    = $i.DisplayName
                    DisplayVersion = $i.DisplayVersion
                    Publisher      = $i.Publisher
                    InstallDate    = $i.InstallDate
                    InstallLocation = $i.InstallLocation
                    Architecture   = $i.Architecture
                    Source         = 'Only in Import'
                })
            }
        }

        # Version differences and matches (same name in both)
        foreach ($key in $scanLookup.Keys) {
            if ($importLookup.ContainsKey($key)) {
                $s = $scanLookup[$key]
                $i = $importLookup[$key]
                $scanVer = if ($s.DisplayVersion) { $s.DisplayVersion.Trim() } else { '' }
                $importVer = if ($i.DisplayVersion) { $i.DisplayVersion.Trim() } else { '' }

                if ($scanVer -ne $importVer) {
                    $comparisonResults.Add([PSCustomObject]@{
                        Machine        = "$($s.Machine) vs $($i.Machine)"
                        DisplayName    = $s.DisplayName
                        DisplayVersion = "$scanVer -> $importVer"
                        Publisher      = $s.Publisher
                        InstallDate    = ''
                        InstallLocation = ''
                        Architecture   = $s.Architecture
                        Source         = 'Version Diff'
                    })
                }
                else {
                    $comparisonResults.Add([PSCustomObject]@{
                        Machine        = $s.Machine
                        DisplayName    = $s.DisplayName
                        DisplayVersion = $s.DisplayVersion
                        Publisher      = $s.Publisher
                        InstallDate    = $s.InstallDate
                        InstallLocation = $s.InstallLocation
                        Architecture   = $s.Architecture
                        Source         = 'Match'
                    })
                }
            }
        }

        # Sort: diffs first, then only-in-scan, then only-in-import, then matches
        $sorted = @($comparisonResults | Sort-Object @{Expression = {
            switch ($_.Source) {
                'Version Diff'   { 0 }
                'Only in Scan'   { 1 }
                'Only in Import' { 2 }
                'Match'          { 3 }
                default          { 4 }
            }
        }}, DisplayName)

        $script:SoftwareInventory = $sorted
        Update-SoftwareDataGrid -Window $Window
        Update-SoftwareStats -Window $Window

        # Summary
        $onlyScan = @($sorted | Where-Object { $_.Source -eq 'Only in Scan' }).Count
        $onlyImport = @($sorted | Where-Object { $_.Source -eq 'Only in Import' }).Count
        $versionDiff = @($sorted | Where-Object { $_.Source -eq 'Version Diff' }).Count
        $matchCount = @($sorted | Where-Object { $_.Source -eq 'Match' }).Count

        $statusText = $Window.FindName('TxtSoftwareStatus')
        if ($statusText) {
            $statusText.Text = "Comparison: $versionDiff version diff(s), $onlyScan only in scan, $onlyImport only in import, $matchCount match"
        }

        Show-Toast -Message "Comparison complete: $matchCount match, $versionDiff version diff(s), $onlyScan scan-only, $onlyImport import-only." -Type 'Success'
    }
    catch {
        Write-AppLockerLog -Message "Software comparison failed: $($_.Exception.Message)" -Level 'ERROR'
        Show-Toast -Message "Comparison failed: $($_.Exception.Message)" -Type 'Error'
    }
    finally {
        Hide-LoadingOverlay
    }
}

function global:Invoke-ClearSoftwareComparison {
    <#
    .SYNOPSIS
        Clears comparison results and imported data.
    #>
    param([System.Windows.Window]$Window)

    $script:SoftwareImportedData = @()
    $script:SoftwareImportedFile = ''
    $script:SoftwareInventory = @()
    $script:CurrentSoftwareSourceFilter = 'All'

    # Reset filter button highlights
    Update-SoftwareSourceFilter -Window $Window -Filter 'All'

    Update-SoftwareDataGrid -Window $Window
    Update-SoftwareStats -Window $Window

    if ($Window) {
        $importedFileText = $Window.FindName('TxtSoftwareImportedFile')
        if ($importedFileText) { $importedFileText.Text = 'None' }

        $lastScan = $Window.FindName('TxtSoftwareLastScan')
        if ($lastScan) { $lastScan.Text = 'None' }

        $statusText = $Window.FindName('TxtSoftwareStatus')
        if ($statusText) { $statusText.Text = 'Ready - scan local machine or import a CSV to get started.' }
    }

    Show-Toast -Message 'Cleared all software inventory data.' -Type 'Info'
}

#endregion

#region ===== DATAGRID UPDATE =====

function global:Update-SoftwareSourceFilter {
    <#
    .SYNOPSIS
        Updates the source filter and refreshes the DataGrid + button highlights.
    #>
    param(
        [System.Windows.Window]$Window,
        [string]$Filter
    )

    # Map filter tag values to Source column values
    $script:CurrentSoftwareSourceFilter = switch ($Filter) {
        'All'          { 'All' }
        'Match'        { 'Match' }
        'VersionDiff'  { 'Version Diff' }
        'OnlyScan'     { 'Only in Scan' }
        'OnlyImport'   { 'Only in Import' }
        default        { 'All' }
    }

    # Update button highlight states
    $allButtons = @(
        'BtnFilterSoftwareAll', 'BtnFilterSoftwareMatch', 'BtnFilterSoftwareVersionDiff',
        'BtnFilterSoftwareOnlyScan', 'BtnFilterSoftwareOnlyImport'
    )

    # Determine which button matches current filter
    $activeBtn = switch ($Filter) {
        'All'          { 'BtnFilterSoftwareAll' }
        'Match'        { 'BtnFilterSoftwareMatch' }
        'VersionDiff'  { 'BtnFilterSoftwareVersionDiff' }
        'OnlyScan'     { 'BtnFilterSoftwareOnlyScan' }
        'OnlyImport'   { 'BtnFilterSoftwareOnlyImport' }
        default        { 'BtnFilterSoftwareAll' }
    }

    if (-not $Window) {
        Update-SoftwareDataGrid -Window $Window
        return
    }

    foreach ($btnName in $allButtons) {
        $btn = $Window.FindName($btnName)
        if ($btn) {
            if ($btnName -eq $activeBtn) {
                $btn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#3E3E42')
                $btn.Foreground = [System.Windows.Media.Brushes]::White
            } else {
                $btn.Background = [System.Windows.Media.Brushes]::Transparent
                # Restore original foreground color
                $btn.Foreground = switch ($btnName) {
                    'BtnFilterSoftwareAll'          { [System.Windows.Media.Brushes]::White }
                    'BtnFilterSoftwareMatch'        { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#1565C0') }
                    'BtnFilterSoftwareVersionDiff'  { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#E6A100') }
                    'BtnFilterSoftwareOnlyScan'     { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#4CAF50') }
                    'BtnFilterSoftwareOnlyImport'   { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#EF5350') }
                }
            }
        }
    }

    Update-SoftwareDataGrid -Window $Window
}

function global:Update-SoftwareDataGrid {
    <#
    .SYNOPSIS
        Updates the SoftwareDataGrid with current inventory data, applying text filter.
    #>
    param([System.Windows.Window]$Window)

    if (-not $Window) { return }
    $dataGrid = $Window.FindName('SoftwareDataGrid')
    if (-not $dataGrid) { return }

    $data = $script:SoftwareInventory

    # Apply source filter (comparison category)
    if ($script:CurrentSoftwareSourceFilter -and $script:CurrentSoftwareSourceFilter -ne 'All') {
        $sourceFilter = $script:CurrentSoftwareSourceFilter
        $data = @($data | Where-Object { $_.Source -eq $sourceFilter })
    }

    # Apply text filter
    $filterBox = $Window.FindName('TxtSoftwareFilter')
    $textFilter = if ($filterBox) { $filterBox.Text } else { '' }

    if (-not [string]::IsNullOrWhiteSpace($textFilter)) {
        $filterText = $textFilter.ToLower()
        $data = @($data | Where-Object {
            ($_.DisplayName -and $_.DisplayName.ToLower().Contains($filterText)) -or
            ($_.Publisher -and $_.Publisher.ToLower().Contains($filterText)) -or
            ($_.DisplayVersion -and $_.DisplayVersion.ToLower().Contains($filterText)) -or
            ($_.Machine -and $_.Machine.ToLower().Contains($filterText)) -or
            ($_.Source -and $_.Source.ToLower().Contains($filterText))
        })
    }

    $dataGrid.ItemsSource = $null
    $dataGrid.ItemsSource = @($data)

    $filteredCount = $Window.FindName('TxtSoftwareFilteredCount')
    if ($filteredCount) { $filteredCount.Text = @($data).Count.ToString() }
}

function global:Update-SoftwareStats {
    <#
    .SYNOPSIS
        Updates the sidebar stats displays.
    #>
    param([System.Windows.Window]$Window)

    if (-not $Window) { return }
    $totalCount = $Window.FindName('TxtSoftwareTotalCount')
    if ($totalCount) { $totalCount.Text = $script:SoftwareInventory.Count.ToString() }

    $machineCount = $Window.FindName('TxtSoftwareMachineCount')
    if ($machineCount) {
        $machines = @($script:SoftwareInventory | ForEach-Object { $_.Machine } | Sort-Object -Unique)
        $machineCount.Text = $machines.Count.ToString()
    }
}

#endregion

#endregion
