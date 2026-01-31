# Enable-WinRM.ps1
# Run as Administrator on each remote machine to enable WinRM for GA-AppLocker scanning
# Applies the same settings as the Initialize-WinRMGPO function (for machines not receiving GPO)
#
# Settings configured:
#   1. WinRM Service auto-start
#   2. WinRM AllowAutoConfig with IPv4/IPv6 filters (listener policy)
#   3. LocalAccountTokenFilterPolicy (enables remote admin for local accounts)
#   4. Firewall rule for WinRM HTTP (port 5985)
#   5. PowerShell Remoting enabled
#   6. Verification

#Requires -RunAsAdministrator

Write-Host "=== GA-AppLocker: Enable WinRM ===" -ForegroundColor Cyan
Write-Host "Matches settings from Initialize-WinRMGPO for standalone machines" -ForegroundColor Gray
Write-Host ""

# 1. WinRM Service Auto-Start
Write-Host "[1/6] Enabling WinRM service (auto-start)..." -ForegroundColor Yellow
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM
Write-Host "      WinRM service: Started (Automatic)" -ForegroundColor Green
Write-Host "      Registry: HKLM\SYSTEM\CurrentControlSet\Services\WinRM\Start = 2" -ForegroundColor Gray

# 2. WinRM AllowAutoConfig with IPv4/IPv6 filters
Write-Host "[2/6] Configuring WinRM listener policy (AllowAutoConfig)..." -ForegroundColor Yellow
$winrmPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service'
if (-not (Test-Path $winrmPolicyPath)) {
    New-Item -Path $winrmPolicyPath -Force | Out-Null
}
Set-ItemProperty -Path $winrmPolicyPath -Name 'AllowAutoConfig' -Value 1 -Type DWord
Set-ItemProperty -Path $winrmPolicyPath -Name 'IPv4Filter' -Value '*' -Type String
Set-ItemProperty -Path $winrmPolicyPath -Name 'IPv6Filter' -Value '*' -Type String
Write-Host "      AllowAutoConfig = 1, IPv4Filter = *, IPv6Filter = *" -ForegroundColor Green

# 3. LocalAccountTokenFilterPolicy (allows local admin remote access)
# Without this, local admin accounts get a filtered (non-elevated) UAC token
# over remote connections and cannot perform admin operations.
# This is the #1 cause of "Access Denied" when credentials are correct.
Write-Host "[3/6] Setting LocalAccountTokenFilterPolicy..." -ForegroundColor Yellow
$uacPolicyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
Set-ItemProperty -Path $uacPolicyPath -Name 'LocalAccountTokenFilterPolicy' -Value 1 -Type DWord
Write-Host "      LocalAccountTokenFilterPolicy = 1 (remote admin enabled)" -ForegroundColor Green

# 4. Firewall rule for WinRM HTTP (port 5985)
Write-Host "[4/6] Configuring firewall rule (port 5985)..." -ForegroundColor Yellow
$ruleName = 'WinRM-HTTP-In'
$existing = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Set-NetFirewallRule -Name $ruleName -Enabled True
    Write-Host "      Firewall: $ruleName -- ENABLED (existing rule)" -ForegroundColor Green
} else {
    New-NetFirewallRule -Name $ruleName `
        -DisplayName "GA-AppLocker: WinRM HTTP (5985)" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 5985 `
        -Action Allow `
        -Profile Domain,Private `
        -Description "Allow WinRM HTTP for GA-AppLocker remote scanning" | Out-Null
    Write-Host "      Firewall: $ruleName -- CREATED (port 5985 inbound allow)" -ForegroundColor Green
}

# 5. Enable PSRemoting
Write-Host "[5/6] Enabling PowerShell Remoting..." -ForegroundColor Yellow
Enable-PSRemoting -Force -SkipNetworkProfileCheck 2>$null
# Set max memory and timeout for large scans
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' 2>$null
winrm set winrm/config '@{MaxTimeoutms="600000"}' 2>$null
Write-Host "      PSRemoting enabled (MaxMemory: 1024MB, Timeout: 10min)" -ForegroundColor Green

# 6. Verify
Write-Host "[6/6] Verifying configuration..." -ForegroundColor Yellow

# Check WinRM listener
$listener = winrm enumerate winrm/config/listener 2>$null
if ($listener -match 'Transport = HTTP') {
    Write-Host "      HTTP listener: Active" -ForegroundColor Green
} else {
    Write-Host "      HTTP listener: NOT FOUND -- run 'winrm quickconfig' manually" -ForegroundColor Red
}

# Check registry values
$autoConfig = Get-ItemProperty -Path $winrmPolicyPath -Name 'AllowAutoConfig' -ErrorAction SilentlyContinue
if ($autoConfig.AllowAutoConfig -eq 1) {
    Write-Host "      AllowAutoConfig: OK" -ForegroundColor Green
} else {
    Write-Host "      AllowAutoConfig: NOT SET" -ForegroundColor Red
}

$tokenPolicy = Get-ItemProperty -Path $uacPolicyPath -Name 'LocalAccountTokenFilterPolicy' -ErrorAction SilentlyContinue
if ($tokenPolicy.LocalAccountTokenFilterPolicy -eq 1) {
    Write-Host "      LocalAccountTokenFilterPolicy: OK" -ForegroundColor Green
} else {
    Write-Host "      LocalAccountTokenFilterPolicy: NOT SET" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== WinRM ENABLED ===" -ForegroundColor Green
Write-Host "Settings match Initialize-WinRMGPO:" -ForegroundColor Gray
Write-Host "  - WinRM service auto-start" -ForegroundColor White
Write-Host "  - AllowAutoConfig with IPv4/IPv6 filters" -ForegroundColor White
Write-Host "  - LocalAccountTokenFilterPolicy = 1" -ForegroundColor White
Write-Host "  - Firewall port 5985 inbound allow" -ForegroundColor White
Write-Host ""
Write-Host "Test from your admin machine:" -ForegroundColor Gray
Write-Host "  Test-WSMan -ComputerName $env:COMPUTERNAME" -ForegroundColor White
Write-Host "  Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock { hostname }" -ForegroundColor White
Write-Host ""
Write-Host "To revert: Run Disable-WinRM.ps1" -ForegroundColor Gray
