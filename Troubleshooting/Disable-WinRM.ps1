# Disable-WinRM.ps1
# Run as Administrator to revert WinRM changes made by Enable-WinRM.ps1
# Reverses all settings applied by Initialize-WinRMGPO / Enable-WinRM.ps1:
#   1. Disable PSRemoting
#   2. Remove AllowAutoConfig registry keys
#   3. Remove LocalAccountTokenFilterPolicy
#   4. Remove firewall rule
#   5. Remove WinRM listener
#   6. Stop and disable WinRM service

#Requires -RunAsAdministrator

Write-Host "=== GA-AppLocker: Disable WinRM ===" -ForegroundColor Cyan
Write-Host "Reverting all settings from Enable-WinRM.ps1 / Initialize-WinRMGPO" -ForegroundColor Gray
Write-Host ""

# 1. Disable PSRemoting
Write-Host "[1/6] Disabling PowerShell Remoting..." -ForegroundColor Yellow
Disable-PSRemoting -Force 2>$null
Write-Host "      PSRemoting disabled" -ForegroundColor Green

# 2. Remove AllowAutoConfig registry keys
Write-Host "[2/6] Removing WinRM AllowAutoConfig policy..." -ForegroundColor Yellow
$winrmPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service'
if (Test-Path $winrmPolicyPath) {
    Remove-ItemProperty -Path $winrmPolicyPath -Name 'AllowAutoConfig' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $winrmPolicyPath -Name 'IPv4Filter' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $winrmPolicyPath -Name 'IPv6Filter' -ErrorAction SilentlyContinue
    # Remove the key if empty
    $remaining = Get-ItemProperty -Path $winrmPolicyPath -ErrorAction SilentlyContinue
    if ($remaining.PSObject.Properties.Name.Count -le 2) {
        # Only PSPath and PSParentPath remain (no real values)
        Remove-Item -Path $winrmPolicyPath -ErrorAction SilentlyContinue
    }
    Write-Host "      AllowAutoConfig, IPv4Filter, IPv6Filter removed" -ForegroundColor Green
} else {
    Write-Host "      WinRM policy key not found (already clean)" -ForegroundColor Gray
}

# 3. Remove LocalAccountTokenFilterPolicy
Write-Host "[3/6] Removing LocalAccountTokenFilterPolicy..." -ForegroundColor Yellow
$uacPolicyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$tokenPolicy = Get-ItemProperty -Path $uacPolicyPath -Name 'LocalAccountTokenFilterPolicy' -ErrorAction SilentlyContinue
if ($null -ne $tokenPolicy.LocalAccountTokenFilterPolicy) {
    Remove-ItemProperty -Path $uacPolicyPath -Name 'LocalAccountTokenFilterPolicy' -ErrorAction SilentlyContinue
    Write-Host "      LocalAccountTokenFilterPolicy removed (UAC filtering restored)" -ForegroundColor Green
} else {
    Write-Host "      LocalAccountTokenFilterPolicy not found (already clean)" -ForegroundColor Gray
}

# 4. Remove firewall rule
Write-Host "[4/6] Removing firewall rule..." -ForegroundColor Yellow
$ruleName = 'WinRM-HTTP-In'
$existing = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Remove-NetFirewallRule -Name $ruleName
    Write-Host "      Removed: $ruleName" -ForegroundColor Green
} else {
    Write-Host "      Not found: $ruleName (already removed)" -ForegroundColor Gray
}

# 5. Delete WinRM listener
Write-Host "[5/6] Removing WinRM listener..." -ForegroundColor Yellow
winrm delete winrm/config/listener?Address=*+Transport=HTTP 2>$null
Write-Host "      HTTP listener removed" -ForegroundColor Green

# 6. Stop and disable WinRM service
Write-Host "[6/6] Stopping WinRM service..." -ForegroundColor Yellow
Stop-Service -Name WinRM -Force 2>$null
Set-Service -Name WinRM -StartupType Disabled
Write-Host "      WinRM service: Stopped (Disabled)" -ForegroundColor Green

Write-Host ""
Write-Host "=== WinRM DISABLED ===" -ForegroundColor Green
Write-Host "All settings reverted:" -ForegroundColor Gray
Write-Host "  - PSRemoting disabled" -ForegroundColor White
Write-Host "  - AllowAutoConfig policy keys removed" -ForegroundColor White
Write-Host "  - LocalAccountTokenFilterPolicy removed" -ForegroundColor White
Write-Host "  - Firewall rule removed" -ForegroundColor White
Write-Host "  - WinRM listener removed" -ForegroundColor White
Write-Host "  - WinRM service stopped and disabled" -ForegroundColor White
Write-Host ""
Write-Host "To re-enable: Run Enable-WinRM.ps1" -ForegroundColor Gray
