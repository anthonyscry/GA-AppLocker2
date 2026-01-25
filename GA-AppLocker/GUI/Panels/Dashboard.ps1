#region Dashboard Panel Functions
# Dashboard.ps1 - Dashboard panel initialization and stats

function Initialize-DashboardPanel {
    param([System.Windows.Window]$Window)

    # Wire up quick action buttons
    $btnGoToScanner = $Window.FindName('BtnDashGoToScanner')
    if ($btnGoToScanner) { $btnGoToScanner.Add_Click({ Invoke-ButtonAction -Action 'NavScanner' }) }

    $btnGoToRules = $Window.FindName('BtnDashGoToRules')
    if ($btnGoToRules) { $btnGoToRules.Add_Click({ Invoke-ButtonAction -Action 'NavRules' }) }

    $btnQuickScan = $Window.FindName('BtnDashQuickScan')
    if ($btnQuickScan) { $btnQuickScan.Add_Click({ Invoke-ButtonAction -Action 'NavScanner' }) }

    $btnQuickImport = $Window.FindName('BtnDashQuickImport')
    if ($btnQuickImport) { $btnQuickImport.Add_Click({ Invoke-ButtonAction -Action 'NavScanner' }) }

    $btnQuickDeploy = $Window.FindName('BtnDashQuickDeploy')
    if ($btnQuickDeploy) { $btnQuickDeploy.Add_Click({ Invoke-ButtonAction -Action 'NavDeploy' }) }

    # Bulk approve trusted vendors button
    $btnApproveTrusted = $Window.FindName('BtnDashApproveTrusted')
    if ($btnApproveTrusted) { $btnApproveTrusted.Add_Click({ Invoke-ButtonAction -Action 'ApproveTrustedVendors' }) }

    # Remove duplicates button
    $btnRemoveDuplicates = $Window.FindName('BtnDashRemoveDuplicates')
    if ($btnRemoveDuplicates) { $btnRemoveDuplicates.Add_Click({ Invoke-ButtonAction -Action 'RemoveDuplicateRules' }) }

    # Load dashboard data
    Update-DashboardStats -Window $Window
}

function Update-DashboardStats {
    param([System.Windows.Window]$Window)

    # Update stats from actual data
    try {
        # Update charts
        Update-DashboardCharts -Window $Window
        # Machines count (null-safe)
        $statMachines = $Window.FindName('StatMachines')
        if ($statMachines) { 
            $machineCount = if ($script:DiscoveredMachines) { $script:DiscoveredMachines.Count } else { 0 }
            $statMachines.Text = $machineCount.ToString()
        }

        # Artifacts count - sum from all saved scans + current session
        $statArtifacts = $Window.FindName('StatArtifacts')
        if ($statArtifacts) { 
            $totalArtifacts = 0
            # Count current session artifacts
            if ($script:CurrentScanArtifacts) {
                $totalArtifacts += $script:CurrentScanArtifacts.Count
            }
            # Also count from saved scans
            $scansResult = Get-ScanResults
            if ($scansResult.Success -and $scansResult.Data) {
                $scanData = @($scansResult.Data)
                foreach ($scan in $scanData) {
                    if ($scan.Artifacts) {
                        $totalArtifacts += [int]$scan.Artifacts
                    }
                }
            }
            $statArtifacts.Text = $totalArtifacts.ToString()
        }

        # Rules count
        $statRules = $Window.FindName('StatRules')
        $statPending = $Window.FindName('StatPending')
        $statApproved = $Window.FindName('StatApproved')
        $statRejected = $Window.FindName('StatRejected')
        $rulesResult = Get-AllRules
        if ($rulesResult.Success) {
            $allRules = @($rulesResult.Data)
            # Rules = Total rules count
            if ($statRules) { 
                $statRules.Text = $allRules.Count.ToString() 
            }
            
            # Group by status for counts
            $statusGroups = $allRules | Group-Object Status
            
            # Pending = Rules awaiting approval
            if ($statPending) {
                $pendingCount = ($statusGroups | Where-Object Name -eq 'Pending' | Select-Object -ExpandProperty Count) -as [int]
                $statPending.Text = $(if ($pendingCount) { $pendingCount } else { 0 }).ToString()
            }
            
            # Approved count
            if ($statApproved) {
                $approvedCount = ($statusGroups | Where-Object Name -eq 'Approved' | Select-Object -ExpandProperty Count) -as [int]
                $statApproved.Text = $(if ($approvedCount) { $approvedCount } else { 0 }).ToString()
            }
            
            # Rejected count
            if ($statRejected) {
                $rejectedCount = ($statusGroups | Where-Object Name -eq 'Rejected' | Select-Object -ExpandProperty Count) -as [int]
                $statRejected.Text = $(if ($rejectedCount) { $rejectedCount } else { 0 }).ToString()
            }

            # Populate pending rules list
            $pendingList = $Window.FindName('DashPendingRules')
            if ($pendingList) {
                $pendingRules = @($allRules | Where-Object { $_.Status -eq 'Pending' } | Select-Object -First 10 | ForEach-Object {
                        [PSCustomObject]@{
                            Type = $_.RuleType
                            Name = $_.Name
                        }
                    })
                $pendingList.ItemsSource = $pendingRules
            }
        }

        # Policies count
        $statPolicies = $Window.FindName('StatPolicies')
        $policiesResult = Get-AllPolicies
        if ($policiesResult.Success -and $statPolicies) {
            $statPolicies.Text = $policiesResult.Data.Count.ToString()
        }

        # Recent scans
        $scansList = $Window.FindName('DashRecentScans')
        if ($scansList) {
            $scansResult = Get-ScanResults
            if ($scansResult.Success -and $scansResult.Data) {
                # Ensure Data is always an array
                $scanData = @($scansResult.Data)
                $recentScans = @($scanData | Select-Object -First 5 | ForEach-Object {
                        # Safely parse Date (may be DateTime, string, or PSCustomObject from JSON)
                        $dateDisplay = ''
                        if ($_.Date) {
                            try {
                                $dateValue = $_.Date
                                if ($dateValue -is [PSCustomObject] -and $dateValue.DateTime) {
                                    $dateDisplay = ([datetime]$dateValue.DateTime).ToString('MM/dd HH:mm')
                                }
                                elseif ($dateValue -is [datetime]) {
                                    $dateDisplay = $dateValue.ToString('MM/dd HH:mm')
                                }
                                elseif ($dateValue -is [string]) {
                                    $dateDisplay = ([datetime]$dateValue).ToString('MM/dd HH:mm')
                                }
                            } catch { }
                        }
                        [PSCustomObject]@{
                            Name  = $_.ScanName
                            Date  = $dateDisplay
                            Count = "$($_.Artifacts) items"
                        }
                    })
                $scansList.ItemsSource = $recentScans
            }
        }
    }
    catch {
        Write-Log -Level Warning -Message "Failed to update dashboard stats: $($_.Exception.Message)"
    }
}

function Update-DashboardCharts {
    <#
    .SYNOPSIS
        Updates the dashboard chart widgets with current data.
    #>
    param([System.Windows.Window]$Window)
    
    try {
        $rulesResult = Get-AllRules
        if (-not $rulesResult.Success) { return }
        
        $allRules = @($rulesResult.Data)
        $totalRules = $allRules.Count
        
        if ($totalRules -eq 0) { return }
        
        # Group by status
        $statusGroups = $allRules | Group-Object Status
        $approved = ($statusGroups | Where-Object Name -eq 'Approved' | Select-Object -ExpandProperty Count) -as [int]
        $pending = ($statusGroups | Where-Object Name -eq 'Pending' | Select-Object -ExpandProperty Count) -as [int]
        $rejected = ($statusGroups | Where-Object Name -eq 'Rejected' | Select-Object -ExpandProperty Count) -as [int]
        $review = ($statusGroups | Where-Object Name -eq 'Review' | Select-Object -ExpandProperty Count) -as [int]
        
        if (-not $approved) { $approved = 0 }
        if (-not $pending) { $pending = 0 }
        if (-not $rejected) { $rejected = 0 }
        if (-not $review) { $review = 0 }
        
        # Group by rule type
        $typeGroups = $allRules | Group-Object RuleType
        $publisherCount = ($typeGroups | Where-Object Name -eq 'Publisher' | Select-Object -ExpandProperty Count) -as [int]
        $hashCount = ($typeGroups | Where-Object Name -eq 'Hash' | Select-Object -ExpandProperty Count) -as [int]
        $pathCount = ($typeGroups | Where-Object Name -eq 'Path' | Select-Object -ExpandProperty Count) -as [int]
        
        if (-not $publisherCount) { $publisherCount = 0 }
        if (-not $hashCount) { $hashCount = 0 }
        if (-not $pathCount) { $pathCount = 0 }
        
        # Calculate max for scaling (use 200 pixels as max width)
        $maxBarWidth = 200
        $maxStatus = [Math]::Max([Math]::Max($approved, $pending), [Math]::Max($rejected, $review))
        $maxType = [Math]::Max([Math]::Max($publisherCount, $hashCount), $pathCount)
        
        if ($maxStatus -eq 0) { $maxStatus = 1 }
        if ($maxType -eq 0) { $maxType = 1 }
        
        # Update Status Chart bars and labels
        $barApproved = $Window.FindName('ChartBarApproved')
        $barPending = $Window.FindName('ChartBarPending')
        $barRejected = $Window.FindName('ChartBarRejected')
        $barReview = $Window.FindName('ChartBarReview')
        
        $labelApproved = $Window.FindName('ChartLabelApproved')
        $labelPending = $Window.FindName('ChartLabelPending')
        $labelRejected = $Window.FindName('ChartLabelRejected')
        $labelReview = $Window.FindName('ChartLabelReview')
        $labelTotal = $Window.FindName('ChartTotalRules')
        
        if ($barApproved) { $barApproved.Width = [Math]::Max(($approved / $maxStatus) * $maxBarWidth, 2) }
        if ($barPending) { $barPending.Width = [Math]::Max(($pending / $maxStatus) * $maxBarWidth, 2) }
        if ($barRejected) { $barRejected.Width = [Math]::Max(($rejected / $maxStatus) * $maxBarWidth, 2) }
        if ($barReview) { $barReview.Width = [Math]::Max(($review / $maxStatus) * $maxBarWidth, 2) }
        
        if ($labelApproved) { $labelApproved.Text = $approved.ToString() }
        if ($labelPending) { $labelPending.Text = $pending.ToString() }
        if ($labelRejected) { $labelRejected.Text = $rejected.ToString() }
        if ($labelReview) { $labelReview.Text = $review.ToString() }
        if ($labelTotal) { $labelTotal.Text = $totalRules.ToString() }
        
        # Update Type Chart bars and labels
        $barPublisher = $Window.FindName('ChartBarPublisher')
        $barHash = $Window.FindName('ChartBarHash')
        $barPath = $Window.FindName('ChartBarPath')
        
        $labelPublisher = $Window.FindName('ChartLabelPublisher')
        $labelHash = $Window.FindName('ChartLabelHash')
        $labelPath = $Window.FindName('ChartLabelPath')
        
        if ($barPublisher) { $barPublisher.Width = [Math]::Max(($publisherCount / $maxType) * $maxBarWidth, 2) }
        if ($barHash) { $barHash.Width = [Math]::Max(($hashCount / $maxType) * $maxBarWidth, 2) }
        if ($barPath) { $barPath.Width = [Math]::Max(($pathCount / $maxType) * $maxBarWidth, 2) }
        
        if ($labelPublisher) { $labelPublisher.Text = $publisherCount.ToString() }
        if ($labelHash) { $labelHash.Text = $hashCount.ToString() }
        if ($labelPath) { $labelPath.Text = $pathCount.ToString() }
    }
    catch {
        Write-Log -Level Warning -Message "Failed to update dashboard charts: $($_.Exception.Message)"
    }
}

#endregion
