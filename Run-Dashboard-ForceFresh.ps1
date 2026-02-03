# GA-AppLocker Dashboard Launcher (FORCE FRESH LOAD)
# Use this if you're getting old version numbers in logs
# This script aggressively clears all PowerShell module caches

Write-Host "=== GA-AppLocker Force Fresh Launcher ===" -ForegroundColor Cyan
Write-Host ""

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Step 1: Remove all loaded GA-AppLocker modules
Write-Host "[1/5] Removing loaded modules..." -ForegroundColor Yellow
$removed = 0
Get-Module GA-AppLocker* | ForEach-Object {
    Write-Host "  Removing: $($_.Name) v$($_.Version)" -ForegroundColor Gray
    Remove-Module $_.Name -Force -ErrorAction SilentlyContinue
    $removed++
}
if ($removed -eq 0) {
    Write-Host "  No modules were loaded" -ForegroundColor Gray
}

# Step 2: Clear PowerShell module analysis cache
Write-Host "[2/5] Clearing module analysis cache..." -ForegroundColor Yellow
$cacheFile = "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\ModuleAnalysisCache"
if (Test-Path $cacheFile) {
    try {
        Remove-Item $cacheFile -Force -ErrorAction Stop
        Write-Host "  Cache cleared: $cacheFile" -ForegroundColor Green
    } catch {
        Write-Host "  Warning: Could not delete cache (may be in use)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Cache file not found (already clean)" -ForegroundColor Gray
}

# Step 3: Verify manifest version
Write-Host "[3/5] Verifying manifest version..." -ForegroundColor Yellow
$modulePath = "$PSScriptRoot\GA-AppLocker\GA-AppLocker.psd1"
if (-not (Test-Path $modulePath)) {
    $modulePath = "$PSScriptRoot\GA-AppLocker.psd1"
}

if (Test-Path $modulePath) {
    $manifestContent = Get-Content $modulePath -Raw
    if ($manifestContent -match "ModuleVersion\s*=\s*'([^']+)'") {
        $fileVersion = $Matches[1]
        Write-Host "  File system version: $fileVersion" -ForegroundColor Green
    } else {
        Write-Host "  Warning: Could not parse version from manifest" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ERROR: Manifest not found at $modulePath" -ForegroundColor Red
    exit 1
}

# Step 4: Import module with -Force
Write-Host "[4/5] Importing module (forced)..." -ForegroundColor Yellow
try {
    Import-Module $modulePath -Force -DisableNameChecking -ErrorAction Stop
    $loadedModule = Get-Module GA-AppLocker
    if ($loadedModule) {
        Write-Host "  Loaded: GA-AppLocker v$($loadedModule.Version)" -ForegroundColor Green
        
        # Verify version matches
        if ($loadedModule.Version.ToString() -ne $fileVersion) {
            Write-Host "  WARNING: Version mismatch!" -ForegroundColor Red
            Write-Host "    File system: $fileVersion" -ForegroundColor Red
            Write-Host "    Loaded:      $($loadedModule.Version)" -ForegroundColor Red
            Write-Host ""
            Write-Host "  This means PowerShell is still caching the old version." -ForegroundColor Red
            Write-Host "  Try closing ALL PowerShell windows and running this script again." -ForegroundColor Red
            Write-Host ""
            $continue = Read-Host "Continue anyway? (y/n)"
            if ($continue -ne 'y') {
                exit 1
            }
        }
    } else {
        Write-Host "  ERROR: Module loaded but Get-Module returned null" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERROR: Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 5: Start dashboard
Write-Host "[5/5] Starting dashboard..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=== Dashboard Starting ===" -ForegroundColor Cyan
Write-Host "Check the log for version confirmation:" -ForegroundColor Gray
Write-Host "  $env:LOCALAPPDATA\GA-AppLocker\Logs\GA-AppLocker_$(Get-Date -Format 'yyyy-MM-dd').log" -ForegroundColor Gray
Write-Host ""

Start-AppLockerDashboard -SkipPrerequisites
