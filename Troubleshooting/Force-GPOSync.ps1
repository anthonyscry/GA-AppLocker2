# Force-GPOSync.ps1
# Run as Administrator ON THE DOMAIN CONTROLLER to force all domain machines to update Group Policy
# Useful after pushing WinRM GPO or AppLocker policy changes

#Requires -RunAsAdministrator

Write-Host "=== GA-AppLocker: Force Domain-Wide GPO Sync ===" -ForegroundColor Cyan
Write-Host ""

# 1. Force replication between DCs (if multiple DCs exist)
Write-Host "[1/3] Forcing AD replication..." -ForegroundColor Yellow
try {
    repadmin /syncall /AdeP 2>$null
    Write-Host "      AD replication triggered" -ForegroundColor Green
} catch {
    Write-Host "      Single DC or repadmin unavailable — skipping" -ForegroundColor Gray
}

# 2. Force gpupdate on all domain computers via Invoke-GPUpdate (requires GroupPolicy module)
Write-Host "[2/3] Forcing GPO refresh on all domain computers..." -ForegroundColor Yellow
$gpModule = Get-Module -ListAvailable -Name GroupPolicy
if ($gpModule) {
    Import-Module GroupPolicy -ErrorAction SilentlyContinue

    # Get all computer names from AD
    $computers = @()
    try {
        # Try AD module first
        if (Get-Command Get-ADComputer -ErrorAction SilentlyContinue) {
            $computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
        } else {
            # LDAP fallback
            $searcher = [adsisearcher]"(objectClass=computer)"
            $searcher.PropertiesToLoad.Add('name') | Out-Null
            $computers = $searcher.FindAll() | ForEach-Object { $_.Properties['name'][0] }
        }
    } catch {
        Write-Host "      Failed to enumerate computers: $($_.Exception.Message)" -ForegroundColor Red
    }

    if ($computers.Count -gt 0) {
        Write-Host "      Found $($computers.Count) computer(s) in domain" -ForegroundColor Gray
        $success = 0
        $failed = 0
        foreach ($computer in $computers) {
            try {
                Invoke-GPUpdate -Computer $computer -Force -RandomDelayInMinutes 0 -ErrorAction Stop
                $success++
                Write-Host "      $computer — GPO refresh triggered" -ForegroundColor Green
            } catch {
                $failed++
                Write-Host "      $computer — FAILED ($($_.Exception.Message))" -ForegroundColor Red
            }
        }
        Write-Host ""
        Write-Host "      Results: $success succeeded, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })
    } else {
        Write-Host "      No computers found in domain" -ForegroundColor Red
    }
} else {
    # Fallback: use gpupdate locally + psexec-style Invoke-Command
    Write-Host "      GroupPolicy module not available — using Invoke-Command fallback" -ForegroundColor Yellow
    
    $computers = @()
    try {
        $searcher = [adsisearcher]"(objectClass=computer)"
        $searcher.PropertiesToLoad.Add('name') | Out-Null
        $computers = $searcher.FindAll() | ForEach-Object { $_.Properties['name'][0] }
    } catch {
        Write-Host "      Failed to enumerate computers: $($_.Exception.Message)" -ForegroundColor Red
    }

    if ($computers.Count -gt 0) {
        Write-Host "      Found $($computers.Count) computer(s) — sending gpupdate via WinRM..." -ForegroundColor Gray
        $results = Invoke-Command -ComputerName $computers -ScriptBlock {
            gpupdate /force /wait:0 2>&1 | Out-Null
            return "$env:COMPUTERNAME — OK"
        } -ErrorAction SilentlyContinue -ErrorVariable gpErrors

        foreach ($r in $results) { Write-Host "      $r" -ForegroundColor Green }
        foreach ($e in $gpErrors) { Write-Host "      FAILED: $($e.TargetObject) — $($e.Exception.Message)" -ForegroundColor Red }
    }
}

# 3. Force gpupdate on THIS machine (the DC)
Write-Host "[3/3] Updating local Group Policy..." -ForegroundColor Yellow
gpupdate /force /wait:0 2>&1 | Out-Null
Write-Host "      Local GPO refreshed" -ForegroundColor Green

Write-Host ""
Write-Host "=== GPO SYNC COMPLETE ===" -ForegroundColor Green
Write-Host "Machines will apply new policies within the next few minutes." -ForegroundColor Gray
Write-Host "Verify with: gpresult /r (on target machine)" -ForegroundColor Gray
