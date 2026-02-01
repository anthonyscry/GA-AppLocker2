#region Setup Panel Functions
# Setup.ps1 - Setup panel handlers
function Initialize-SetupPanel {
    param([System.Windows.Window]$Window)

    # Wire up Setup tab buttons - WinRM GPOs
    $btnInitWinRM = $Window.FindName('BtnInitializeWinRM')
    if ($btnInitWinRM) { $btnInitWinRM.Add_Click({ Invoke-ButtonAction -Action 'InitializeWinRM' }) }

    $btnToggleEnable = $Window.FindName('BtnToggleEnableWinRM')
    if ($btnToggleEnable) { $btnToggleEnable.Add_Click({ Invoke-ButtonAction -Action 'ToggleEnableWinRM' }) }

    $btnRemoveEnable = $Window.FindName('BtnRemoveEnableWinRM')
    if ($btnRemoveEnable) { $btnRemoveEnable.Add_Click({ Invoke-ButtonAction -Action 'RemoveEnableWinRM' }) }

    $btnToggleDisable = $Window.FindName('BtnToggleDisableWinRM')
    if ($btnToggleDisable) { $btnToggleDisable.Add_Click({ Invoke-ButtonAction -Action 'ToggleDisableWinRM' }) }

    $btnRemoveDisable = $Window.FindName('BtnRemoveDisableWinRM')
    if ($btnRemoveDisable) { $btnRemoveDisable.Add_Click({ Invoke-ButtonAction -Action 'RemoveDisableWinRM' }) }

    $btnInitGPOs = $Window.FindName('BtnInitializeAppLockerGPOs')
    if ($btnInitGPOs) { $btnInitGPOs.Add_Click({ Invoke-ButtonAction -Action 'InitializeAppLockerGPOs' }) }

    $btnInitAD = $Window.FindName('BtnInitializeADStructure')
    if ($btnInitAD) { $btnInitAD.Add_Click({ Invoke-ButtonAction -Action 'InitializeADStructure' }) }

    $btnInitAll = $Window.FindName('BtnInitializeAll')
    if ($btnInitAll) { $btnInitAll.Add_Click({ Invoke-ButtonAction -Action 'InitializeAll' }) }

    # Update status on load
    Update-SetupStatus -Window $Window
}

function Update-SetupStatus {
    param([System.Windows.Window]$Window)

    try {
        # Use try-catch - Get-Command fails in WPF context
        $status = $null
        try { $status = Get-SetupStatus } catch { return }
        if (-not $status) { return }

        if ($status.Success -and $status.Data) {
            # Update EnableWinRM GPO status
            $enableStatus = $Window.FindName('TxtEnableWinRMStatus')
            if ($enableStatus -and $status.Data.WinRM) {
                $enableStatus.Text = $status.Data.WinRM.Status
                $enableStatus.Foreground = switch ($status.Data.WinRM.Status) {
                    'Enabled' { [System.Windows.Media.Brushes]::LightGreen }
                    'Disabled' { [System.Windows.Media.Brushes]::Orange }
                    default { [System.Windows.Media.Brushes]::Gray }
                }
            }

            # Update EnableWinRM toggle button label
            $btnToggleEnable = $Window.FindName('BtnToggleEnableWinRM')
            if ($btnToggleEnable -and $status.Data.WinRM) {
                if ($status.Data.WinRM.Status -eq 'Enabled') {
                    $btnToggleEnable.Content = 'Disable Link'
                } else {
                    $btnToggleEnable.Content = 'Enable Link'
                }
            }

            # Update DisableWinRM GPO status
            $disableStatus = $Window.FindName('TxtDisableWinRMStatus')
            if ($disableStatus -and $status.Data.DisableWinRM) {
                $disableStatus.Text = $status.Data.DisableWinRM.Status
                $disableStatus.Foreground = switch ($status.Data.DisableWinRM.Status) {
                    'Enabled' { [System.Windows.Media.Brushes]::LightGreen }
                    'Disabled' { [System.Windows.Media.Brushes]::Orange }
                    default { [System.Windows.Media.Brushes]::Gray }
                }
            }

            # Update DisableWinRM toggle button label
            $btnToggleDisable = $Window.FindName('BtnToggleDisableWinRM')
            if ($btnToggleDisable -and $status.Data.DisableWinRM) {
                if ($status.Data.DisableWinRM.Status -eq 'Enabled') {
                    $btnToggleDisable.Content = 'Disable Link'
                } else {
                    $btnToggleDisable.Content = 'Enable Link'
                }
            }

            # Update GPO statuses
            foreach ($gpo in $status.Data.AppLockerGPOs) {
                $statusControl = $Window.FindName("TxtGPO_$($gpo.Type)_Status")
                if ($statusControl) {
                    $statusControl.Text = $gpo.Status
                    $statusControl.Foreground = if ($gpo.Exists) { 
                        [System.Windows.Media.Brushes]::LightGreen 
                    }
                    else { 
                        [System.Windows.Media.Brushes]::Gray 
                    }
                }
            }
        }
    }
    catch {
        # Silently fail - status display is optional
    }
}

function global:Invoke-InitializeWinRM {
    param([System.Windows.Window]$Window)

    try {
        $confirm = [System.Windows.MessageBox]::Show(
            "This will create two WinRM GPOs linked to the domain root:`n`n" +
            "1. AppLocker-EnableWinRM - enables WinRM on all computers`n" +
            "2. AppLocker-DisableWinRM - tattoo removal (link starts disabled)`n`n" +
            "Requires Domain Admin permissions.`n`nContinue?",
            'Initialize WinRM GPOs',
            'YesNo',
            'Warning'
        )

        if ($confirm -ne 'Yes') { return }

        Show-LoadingOverlay -Message 'Creating WinRM GPOs...' -SubMessage 'Setting up Enable + Disable GPOs'

        # Create Enable GPO (linked + enabled)
        $enableResult = Initialize-WinRMGPO

        # Create Disable GPO (linked + enforced - but Initialize-DisableWinRMGPO also disables the Enable link)
        $disableResult = Initialize-DisableWinRMGPO

        # Fix link states: Enable GPO active, Disable GPO inactive (ready but not applied)
        try {
            Enable-WinRMGPO -GPOName 'AppLocker-EnableWinRM' -ErrorAction SilentlyContinue
            Disable-WinRMGPO -GPOName 'AppLocker-DisableWinRM' -ErrorAction SilentlyContinue
        } catch { }

        Hide-LoadingOverlay

        $summary = @()
        if ($enableResult.Success) { $summary += "EnableWinRM: Created" } else { $summary += "EnableWinRM: Failed - $($enableResult.Error)" }
        if ($disableResult.Success) { $summary += "DisableWinRM: Created (link disabled)" } else { $summary += "DisableWinRM: Failed - $($disableResult.Error)" }

        if ($enableResult.Success -or $disableResult.Success) {
            [System.Windows.MessageBox]::Show(
                "WinRM GPOs initialized!`n`n$($summary -join "`n")",
                'Success',
                'OK',
                'Information'
            )
        }
        else {
            [System.Windows.MessageBox]::Show("Both GPOs failed:`n`n$($summary -join "`n")", 'Error', 'OK', 'Error')
        }

        Update-SetupStatus -Window $Window
    }
    catch {
        Hide-LoadingOverlay
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", 'Error', 'OK', 'Error')
    }
}

function global:Invoke-ToggleWinRMGPO {
    param(
        [System.Windows.Window]$Window,
        [string]$GPOName,
        [string]$StatusProperty
    )

    try {
        $status = Get-SetupStatus
        if (-not $status.Success) {
            [System.Windows.MessageBox]::Show('Could not read GPO status.', 'Error', 'OK', 'Error')
            return
        }

        $gpoStatus = $status.Data.$StatusProperty
        if (-not $gpoStatus -or -not $gpoStatus.Exists) {
            [System.Windows.MessageBox]::Show("GPO '$GPOName' does not exist. Initialize WinRM GPOs first.", 'Not Found', 'OK', 'Warning')
            return
        }

        $isEnabled = $gpoStatus.Status -eq 'Enabled'

        if ($isEnabled) {
            $result = Disable-WinRMGPO -GPOName $GPOName
            $action = 'disabled'
        }
        else {
            $result = Enable-WinRMGPO -GPOName $GPOName
            $action = 'enabled'
        }

        if ($result.Success) {
            $message = "$GPOName link $action."

            # Mutual exclusivity: when ENABLING one GPO, auto-disable the opposite
            if ($action -eq 'enabled') {
                $oppositeGPO = $null
                $oppositeProperty = $null
                if ($GPOName -eq 'AppLocker-EnableWinRM') {
                    $oppositeGPO = 'AppLocker-DisableWinRM'
                    $oppositeProperty = 'DisableWinRM'
                }
                elseif ($GPOName -eq 'AppLocker-DisableWinRM') {
                    $oppositeGPO = 'AppLocker-EnableWinRM'
                    $oppositeProperty = 'WinRM'
                }

                if ($oppositeGPO) {
                    $oppositeStatus = $status.Data.$oppositeProperty
                    if ($oppositeStatus -and $oppositeStatus.Exists -and $oppositeStatus.Status -eq 'Enabled') {
                        $disableOpposite = Disable-WinRMGPO -GPOName $oppositeGPO
                        if ($disableOpposite.Success) {
                            $message += "`n$oppositeGPO link auto-disabled (mutually exclusive)."
                        }
                    }
                }
            }

            [System.Windows.MessageBox]::Show($message, 'Success', 'OK', 'Information')
            Update-SetupStatus -Window $Window
        }
        else {
            [System.Windows.MessageBox]::Show("Failed: $($result.Error)", 'Error', 'OK', 'Error')
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", 'Error', 'OK', 'Error')
    }
}

function global:Invoke-RemoveWinRMGPOByName {
    param(
        [System.Windows.Window]$Window,
        [string]$GPOName,
        [string]$StatusProperty,
        [string]$RemoveFunction
    )

    try {
        $status = Get-SetupStatus
        if (-not $status.Success) {
            [System.Windows.MessageBox]::Show('Could not read GPO status.', 'Error', 'OK', 'Error')
            return
        }

        $gpoStatus = $status.Data.$StatusProperty
        if (-not $gpoStatus -or -not $gpoStatus.Exists) {
            [System.Windows.MessageBox]::Show("GPO '$GPOName' does not exist. Nothing to remove.", 'Not Found', 'OK', 'Warning')
            return
        }

        $confirm = [System.Windows.MessageBox]::Show(
            "This will PERMANENTLY remove '$GPOName' and all its links.`n`nAre you sure?",
            "Remove $GPOName",
            'YesNo',
            'Warning'
        )

        if ($confirm -ne 'Yes') { return }

        $result = & $RemoveFunction -GPOName $GPOName

        if ($result.Success) {
            [System.Windows.MessageBox]::Show(
                "$GPOName removed.",
                'Removed',
                'OK',
                'Information'
            )
            Update-SetupStatus -Window $Window
        }
        else {
            [System.Windows.MessageBox]::Show("Failed: $($result.Error)", 'Error', 'OK', 'Error')
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", 'Error', 'OK', 'Error')
    }
}

function global:Invoke-InitializeAppLockerGPOs {
    param([System.Windows.Window]$Window)

    try {
        $confirm = [System.Windows.MessageBox]::Show(
            "This will create three AppLocker GPOs:`n`n" +
            "- AppLocker-DC (linked to Domain Controllers OU)`n" +
            "- AppLocker-Servers (linked to Servers OU)`n" +
            "- AppLocker-Workstations (linked to Computers OU)`n`n" +
            "Continue?",
            'Initialize AppLocker GPOs',
            'YesNo',
            'Question'
        )

        if ($confirm -ne 'Yes') { return }

        $result = Initialize-AppLockerGPOs

        if ($result.Success) {
            $summary = $result.Data | ForEach-Object { "- $($_.Name): $($_.Status)" }
            [System.Windows.MessageBox]::Show(
                "AppLocker GPOs created!`n`n$($summary -join "`n")",
                'Success',
                'OK',
                'Information'
            )
            Update-SetupStatus -Window $Window
        }
        else {
            [System.Windows.MessageBox]::Show("Failed: $($result.Error)", 'Error', 'OK', 'Error')
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", 'Error', 'OK', 'Error')
    }
}

function global:Invoke-InitializeADStructure {
    param([System.Windows.Window]$Window)

    try {
        $confirm = [System.Windows.MessageBox]::Show(
            "This will create the AppLocker OU and security groups:`n`n" +
            "OU: AppLocker (at domain root)`n`n" +
            "Groups:`n" +
            "- AppLocker-Admins`n" +
            "- AppLocker-Exempt`n" +
            "- AppLocker-Audit`n" +
            "- AppLocker-Users`n" +
            "- AppLocker-Installers`n" +
            "- AppLocker-Developers`n`n" +
            "Continue?",
            'Initialize AD Structure',
            'YesNo',
            'Question'
        )

        if ($confirm -ne 'Yes') { return }

        $result = Initialize-ADStructure

        if ($result.Success) {
            $groupSummary = $result.Data.Groups | ForEach-Object { "- $($_.Name): $($_.Status)" }
            [System.Windows.MessageBox]::Show(
                "AD Structure created!`n`n" +
                "OU: $($result.Data.OUPath)`n`n" +
                "Groups:`n$($groupSummary -join "`n")",
                'Success',
                'OK',
                'Information'
            )
            Update-SetupStatus -Window $Window
        }
        else {
            [System.Windows.MessageBox]::Show("Failed: $($result.Error)", 'Error', 'OK', 'Error')
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", 'Error', 'OK', 'Error')
    }
}

function global:Invoke-InitializeAll {
    param([System.Windows.Window]$Window)

    try {
        $confirm = [System.Windows.MessageBox]::Show(
            "This will run ALL initialization steps:`n`n" +
            "1. Create WinRM GPO (linked to domain root)`n" +
            "2. Create AppLocker GPOs (DC, Servers, Workstations)`n" +
            "3. Create AppLocker OU and security groups`n`n" +
            "This requires Domain Admin permissions.`n`n" +
            "Continue?",
            'Full Initialization',
            'YesNo',
            'Warning'
        )

        if ($confirm -ne 'Yes') { return }

        $result = Initialize-AppLockerEnvironment

        if ($result.Success) {
            [System.Windows.MessageBox]::Show(
                "Full initialization complete!`n`n" +
                "WinRM GPO: $(if ($result.Data.WinRM.Success) { 'Success' } else { 'Failed' })`n" +
                "AppLocker GPOs: $(if ($result.Data.AppLockerGPOs.Success) { 'Success' } else { 'Failed' })`n" +
                "AD Structure: $(if ($result.Data.ADStructure.Success) { 'Success' } else { 'Failed' })",
                'Initialization Complete',
                'OK',
                'Information'
            )
            Update-SetupStatus -Window $Window
        }
        else {
            [System.Windows.MessageBox]::Show("Failed: $($result.Error)", 'Error', 'OK', 'Error')
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", 'Error', 'OK', 'Error')
    }
}

#endregion

#region ===== WINDOW INITIALIZATION =====
#endregion
