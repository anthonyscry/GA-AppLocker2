# Disable-WinRM.ps1
# Run as Administrator to revert WinRM changes made by Enable-WinRM.ps1
# Disables PSRemoting, closes firewall ports, stops WinRM service

#Requires -RunAsAdministrator

Write-Host "=== GA-AppLocker: Disable WinRM ===" -ForegroundColor Cyan
Write-Host ""

# 1. Disable PSRemoting
Write-Host "[1/4] Disabling PowerShell Remoting..." -ForegroundColor Yellow
Disable-PSRemoting -Force 2>$null
Write-Host "      PSRemoting disabled" -ForegroundColor Green

# 2. Remove firewall rules
Write-Host "[2/4] Removing firewall rules..." -ForegroundColor Yellow
$ruleNames = @('WinRM-HTTP-In', 'WinRM-HTTPS-In')
foreach ($name in $ruleNames) {
    $existing = Get-NetFirewallRule -Name $name -ErrorAction SilentlyContinue
    if ($existing) {
        Remove-NetFirewallRule -Name $name
        Write-Host "      Removed: $name" -ForegroundColor Green
    } else {
        Write-Host "      Not found: $name (already removed)" -ForegroundColor Gray
    }
}

# 3. Delete WinRM listener
Write-Host "[3/4] Removing WinRM listener..." -ForegroundColor Yellow
winrm delete winrm/config/listener?Address=*+Transport=HTTP 2>$null
Write-Host "      HTTP listener removed" -ForegroundColor Green

# 4. Stop and disable WinRM service
Write-Host "[4/4] Stopping WinRM service..." -ForegroundColor Yellow
Stop-Service -Name WinRM -Force 2>$null
Set-Service -Name WinRM -StartupType Disabled
Write-Host "      WinRM service: Stopped (Disabled)" -ForegroundColor Green

Write-Host ""
Write-Host "=== WinRM DISABLED ===" -ForegroundColor Green
Write-Host "All changes from Enable-WinRM.ps1 have been reverted." -ForegroundColor Gray
Write-Host ""
Write-Host "To re-enable: Run Enable-WinRM.ps1" -ForegroundColor Gray
