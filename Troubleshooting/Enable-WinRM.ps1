# Enable-WinRM.ps1
# Run as Administrator on each remote machine to enable WinRM for GA-AppLocker scanning
# This enables PowerShell remoting, opens firewall ports, and configures WinRM listener

#Requires -RunAsAdministrator

Write-Host "=== GA-AppLocker: Enable WinRM ===" -ForegroundColor Cyan
Write-Host ""

# 1. Enable WinRM service
Write-Host "[1/5] Enabling WinRM service..." -ForegroundColor Yellow
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM
Write-Host "      WinRM service: Started (Automatic)" -ForegroundColor Green

# 2. Configure WinRM
Write-Host "[2/5] Configuring WinRM listener..." -ForegroundColor Yellow
winrm quickconfig -quiet 2>$null
# Set max memory and timeout for large scans
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' 2>$null
winrm set winrm/config '@{MaxTimeoutms="600000"}' 2>$null
Write-Host "      WinRM listener configured (MaxMemory: 1024MB, Timeout: 10min)" -ForegroundColor Green

# 3. Enable PSRemoting
Write-Host "[3/5] Enabling PowerShell Remoting..." -ForegroundColor Yellow
Enable-PSRemoting -Force -SkipNetworkProfileCheck 2>$null
Write-Host "      PSRemoting enabled" -ForegroundColor Green

# 4. Open firewall ports (HTTP 5985, HTTPS 5986)
Write-Host "[4/5] Configuring firewall rules..." -ForegroundColor Yellow
$rules = @(
    @{ Name = 'WinRM-HTTP-In'; Port = 5985; Display = 'WinRM HTTP (5985)' }
    @{ Name = 'WinRM-HTTPS-In'; Port = 5986; Display = 'WinRM HTTPS (5986)' }
)
foreach ($rule in $rules) {
    $existing = Get-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Set-NetFirewallRule -Name $rule.Name -Enabled True
    } else {
        New-NetFirewallRule -Name $rule.Name `
            -DisplayName "GA-AppLocker: $($rule.Display)" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $rule.Port `
            -Action Allow `
            -Profile Domain,Private `
            -Description "Allow WinRM for GA-AppLocker scanning" | Out-Null
    }
    Write-Host "      Firewall: $($rule.Display) — OPEN" -ForegroundColor Green
}

# 5. Set TrustedHosts (for workgroup/cross-domain — skip if domain-only)
Write-Host "[5/5] Verifying configuration..." -ForegroundColor Yellow
$listener = winrm enumerate winrm/config/listener 2>$null
if ($listener -match 'Transport = HTTP') {
    Write-Host "      HTTP listener: Active" -ForegroundColor Green
} else {
    Write-Host "      HTTP listener: NOT FOUND — run 'winrm quickconfig' manually" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== WinRM ENABLED ===" -ForegroundColor Green
Write-Host "Test from your admin machine:" -ForegroundColor Gray
Write-Host "  Test-WSMan -ComputerName $env:COMPUTERNAME" -ForegroundColor White
Write-Host "  Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock { hostname }" -ForegroundColor White
Write-Host ""
Write-Host "To revert: Run Disable-WinRM.ps1" -ForegroundColor Gray
