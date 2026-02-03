# Verify-ModuleVersion.ps1
# Diagnostic script to verify which version of GA-AppLocker is actually loaded

Write-Host "`n=== GA-AppLocker Module Version Diagnostic ===" -ForegroundColor Cyan

# 1. Check file system version
Write-Host "`n1. File System Version:" -ForegroundColor Yellow
$manifestPath = "$PSScriptRoot\..\GA-AppLocker\GA-AppLocker.psd1"
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    if ($manifestContent -match "ModuleVersion\s*=\s*'([^']+)'") {
        Write-Host "   Manifest file version: $($Matches[1])" -ForegroundColor Green
    }
} else {
    Write-Host "   ERROR: Manifest not found at $manifestPath" -ForegroundColor Red
}

# 2. Check loaded module version
Write-Host "`n2. Loaded Module Version:" -ForegroundColor Yellow
$loadedModule = Get-Module GA-AppLocker
if ($loadedModule) {
    Write-Host "   Loaded version: $($loadedModule.Version)" -ForegroundColor Green
    Write-Host "   Loaded from: $($loadedModule.Path)" -ForegroundColor Green
} else {
    Write-Host "   Module not currently loaded" -ForegroundColor Yellow
}

# 3. Check if fixes are present in the actual files
Write-Host "`n3. Verifying Fixes in Code:" -ForegroundColor Yellow

# Bug 1 fix: Line 652 should have @(Get-CheckedMachines)
$adDiscoveryPath = "$PSScriptRoot\..\GA-AppLocker\GUI\Panels\ADDiscovery.ps1"
if (Test-Path $adDiscoveryPath) {
    $line652 = (Get-Content $adDiscoveryPath)[651]  # 0-based index
    if ($line652 -match '@\(Get-CheckedMachines') {
        Write-Host "   [OK] Bug 1 fix present: Line 652 has @(Get-CheckedMachines)" -ForegroundColor Green
    } else {
        Write-Host "   [FAIL] Bug 1 fix MISSING: Line 652 = $line652" -ForegroundColor Red
    }
} else {
    Write-Host "   [ERROR] ADDiscovery.ps1 not found" -ForegroundColor Red
}

# Bug 2 fix: Dashboard.ps1 lines 63-69 should have simplified logic
$dashboardPath = "$PSScriptRoot\..\GA-AppLocker\GUI\Panels\Dashboard.ps1"
if (Test-Path $dashboardPath) {
    $line64 = (Get-Content $dashboardPath)[63]  # 0-based index
    if ($line64 -match 'if \(\$null -eq \$Status\)') {
        Write-Host "   [OK] Bug 2 fix present: Dashboard.ps1 has simplified parameter handling" -ForegroundColor Green
    } else {
        Write-Host "   [FAIL] Bug 2 fix MISSING: Line 64 = $line64" -ForegroundColor Red
    }
} else {
    Write-Host "   [ERROR] Dashboard.ps1 not found" -ForegroundColor Red
}

# Bug 3 fix: Scanner.ps1 should have elevation check around line 298
$scannerPath = "$PSScriptRoot\..\GA-AppLocker\GUI\Panels\Scanner.ps1"
if (Test-Path $scannerPath) {
    $scannerContent = Get-Content $scannerPath -Raw
    if ($scannerContent -match 'Check elevation for local scans') {
        Write-Host "   [OK] Bug 3 fix present: Scanner.ps1 has elevation check" -ForegroundColor Green
    } else {
        Write-Host "   [FAIL] Bug 3 fix MISSING: Elevation check not found" -ForegroundColor Red
    }
} else {
    Write-Host "   [ERROR] Scanner.ps1 not found" -ForegroundColor Red
}

# 4. Check for stale PowerShell sessions
Write-Host "`n4. PowerShell Session Info:" -ForegroundColor Yellow
Write-Host "   Current PID: $PID" -ForegroundColor Cyan
Write-Host "   Session start: $((Get-Process -Id $PID).StartTime)" -ForegroundColor Cyan

# 5. Recommendations
Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
if ($loadedModule -and $loadedModule.Version -ne '1.2.57') {
    Write-Host "   [ACTION REQUIRED] Module version mismatch!" -ForegroundColor Red
    Write-Host "   File system shows 1.2.57 but loaded module is $($loadedModule.Version)" -ForegroundColor Red
    Write-Host "   Run these commands to force reload:" -ForegroundColor Yellow
    Write-Host "   Remove-Module GA-AppLocker -Force -ErrorAction SilentlyContinue" -ForegroundColor White
    Write-Host "   Get-Module GA-AppLocker.* | Remove-Module -Force" -ForegroundColor White
    Write-Host "   Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force" -ForegroundColor White
    Write-Host "   .\Run-Dashboard.ps1" -ForegroundColor White
} elseif (-not $loadedModule) {
    Write-Host "   Module not loaded yet - this is normal if you haven't started the app" -ForegroundColor Green
    Write-Host "   Run: .\Run-Dashboard.ps1" -ForegroundColor White
} else {
    Write-Host "   Module version matches! (1.2.57)" -ForegroundColor Green
    Write-Host "   If bugs persist, the fixes may need adjustment" -ForegroundColor Yellow
}

Write-Host "`n=== End Diagnostic ===" -ForegroundColor Cyan
Write-Host ""
