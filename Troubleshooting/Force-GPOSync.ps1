# Force-GPOSync.ps1
# Run as Administrator ON THE DOMAIN CONTROLLER to force machines to update Group Policy
# Useful after pushing WinRM GPO or AppLocker policy changes
#
# Usage:
#   .\Force-GPOSync.ps1                          # All enabled computers in domain
#   .\Force-GPOSync.ps1 -Target SRV01,SRV02      # Specific machines only
#   .\Force-GPOSync.ps1 -OU "OU=Servers,DC=lab,DC=local"  # Specific OU only
#   .\Force-GPOSync.ps1 -SkipOffline             # Skip ping check (faster, more errors)

#Requires -RunAsAdministrator

param(
    [string[]]$Target,
    [string]$OU,
    [switch]$SkipOffline
)

Write-Host "=== GA-AppLocker: Force GPO Sync ===" -ForegroundColor Cyan
Write-Host ""

# ---- 1. Force AD replication between DCs (if multiple DCs exist) ----
Write-Host "[1/4] Forcing AD replication..." -ForegroundColor Yellow
$repadminPath = "$env:SystemRoot\System32\repadmin.exe"
if (Test-Path $repadminPath) {
    $repadOutput = & repadmin /syncall /AdeP 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      AD replication triggered" -ForegroundColor Green
    } else {
        # Common: single DC has no replication partners
        Write-Host "      Replication skipped (single DC or no partners)" -ForegroundColor Gray
    }
} else {
    Write-Host "      repadmin not found -- skipping (not a DC?)" -ForegroundColor Gray
}

# ---- 2. Enumerate target computers ----
Write-Host "[2/4] Enumerating computers..." -ForegroundColor Yellow
$computers = @()

if ($Target) {
    # Explicit target list
    $computers = $Target
    Write-Host "      Using explicit target list: $($computers.Count) machine(s)" -ForegroundColor Gray
} else {
    # Enumerate from AD
    try {
        if (Get-Command Get-ADComputer -ErrorAction SilentlyContinue) {
            $adParams = @{ Filter = 'Enabled -eq $true' }
            if ($OU) {
                $adParams['SearchBase'] = $OU
                Write-Host "      Searching OU: $OU" -ForegroundColor Gray
            }
            $computers = Get-ADComputer @adParams -Properties LastLogonTimestamp |
                Where-Object {
                    # Skip accounts that haven't logged on in 90+ days (stale)
                    if ($null -eq $_.LastLogonTimestamp) { return $true }  # Never logged on = new, include
                    $lastLogon = [DateTime]::FromFileTime($_.LastLogonTimestamp)
                    return ($lastLogon -gt (Get-Date).AddDays(-90))
                } |
                Select-Object -ExpandProperty Name
        } else {
            # LDAP fallback (no AD module)
            $filter = '(&(objectClass=computer)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'
            if ($OU) {
                $entry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$OU")
                $searcher = New-Object System.DirectoryServices.DirectorySearcher($entry, $filter)
            } else {
                $searcher = [adsisearcher]$filter
            }
            $searcher.PropertiesToLoad.Add('name') | Out-Null
            $searcher.PageSize = 1000
            $computers = $searcher.FindAll() | ForEach-Object { $_.Properties['name'][0] }
        }
    } catch {
        Write-Host "      Failed to enumerate computers: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Exclude this DC from remote list (we update it locally in step 4)
$thisMachine = $env:COMPUTERNAME
$computers = @($computers | Where-Object { $_ -ne $thisMachine })

if ($computers.Count -eq 0) {
    Write-Host "      No remote computers found to update" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "      Found $($computers.Count) enabled computer(s) (excluding this DC)" -ForegroundColor Gray

    # ---- 3. Filter offline machines and push GPO update ----
    Write-Host "[3/4] Pushing GPO refresh to remote machines..." -ForegroundColor Yellow

    $online = @()
    $offline = @()

    if (-not $SkipOffline) {
        Write-Host "      Ping-checking machines..." -ForegroundColor Gray
        foreach ($computer in $computers) {
            $ping = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$computer' AND Timeout=2000" -ErrorAction SilentlyContinue
            if ($ping -and $ping.StatusCode -eq 0) {
                $online += $computer
            } else {
                $offline += $computer
            }
        }
        if ($offline.Count -gt 0) {
            Write-Host "      Offline ($($offline.Count)): $($offline -join ', ')" -ForegroundColor Gray
        }
        Write-Host "      Online: $($online.Count) of $($computers.Count)" -ForegroundColor Gray
    } else {
        $online = $computers
        Write-Host "      Skipping ping check -- targeting all $($online.Count) machines" -ForegroundColor Gray
    }

    # Push GPO update to online machines
    $success = 0
    $failed = 0
    $failedList = @()

    $gpModule = Get-Module -ListAvailable -Name GroupPolicy
    if ($gpModule) {
        Import-Module GroupPolicy -ErrorAction SilentlyContinue
    }

    foreach ($computer in $online) {
        $pushed = $false

        # Try Invoke-GPUpdate first (uses RPC/Task Scheduler, no WinRM needed)
        if ($gpModule) {
            try {
                Invoke-GPUpdate -Computer $computer -Force -RandomDelayInMinutes 0 -ErrorAction Stop
                $pushed = $true
            } catch {
                # RPC failed -- fall through to WinRM
            }
        }

        # Fallback: WinRM (if Invoke-GPUpdate unavailable or RPC failed)
        if (-not $pushed) {
            try {
                $sessionOpt = New-PSSessionOption -OpenTimeout 10000
                Invoke-Command -ComputerName $computer -ScriptBlock {
                    gpupdate /force /wait:0 2>&1 | Out-Null
                } -SessionOption $sessionOpt -ErrorAction Stop
                $pushed = $true
            } catch {
                # Both methods failed
            }
        }

        if ($pushed) {
            $success++
            Write-Host "      $computer -- OK" -ForegroundColor Green
        } else {
            $failed++
            $failedList += $computer
            Write-Host "      $computer -- FAILED (RPC + WinRM unreachable)" -ForegroundColor Red
        }
    }

    Write-Host ""
    if ($failed -eq 0) {
        Write-Host "      Results: $success succeeded, $($offline.Count) offline" -ForegroundColor Green
    } else {
        Write-Host "      Results: $success succeeded, $failed failed, $($offline.Count) offline" -ForegroundColor Yellow
        if ($failedList.Count -gt 0) {
            Write-Host "      Failed: $($failedList -join ', ')" -ForegroundColor Yellow
            Write-Host "      Tip: Run Enable-WinRM.ps1 on failed machines, or wait for GPO propagation" -ForegroundColor Gray
        }
    }
}

# ---- 4. Force gpupdate on THIS machine (the DC) ----
Write-Host "[4/4] Updating local Group Policy..." -ForegroundColor Yellow
$gpOutput = gpupdate /force /wait:0 2>&1
Write-Host "      Local GPO refreshed" -ForegroundColor Green

Write-Host ""
Write-Host "=== GPO SYNC COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Notes:" -ForegroundColor Gray
Write-Host "  - Online machines will apply new policies within minutes" -ForegroundColor White
Write-Host "  - Offline machines will apply on next boot (90-min refresh cycle)" -ForegroundColor White
Write-Host "  - Verify on target: gpresult /r" -ForegroundColor White
Write-Host "  - If pushing WinRM GPO, offline machines get it at next boot automatically" -ForegroundColor White
