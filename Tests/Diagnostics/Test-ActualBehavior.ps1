#Requires -Version 5.1
<#
.SYNOPSIS
    REAL diagnostic tests that actually import the module and test runtime behavior.

.DESCRIPTION
    These tests verify actual functionality, not just source code patterns.
    Run this BEFORE committing any fixes to verify they actually work.
#>

param(
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$testsPassed = 0
$testsFailed = 0
$failures = @()

function Test-Diagnostic {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "`n[TEST] $Name" -ForegroundColor Cyan
    try {
        & $Test
        Write-Host "  [PASS]" -ForegroundColor Green
        $script:testsPassed++
    }
    catch {
        Write-Host "  [FAIL]: $($_.Exception.Message)" -ForegroundColor Red
        $script:testsFailed++
        $script:failures += @{Name=$Name; Error=$_.Exception.Message}
    }
}

# Clean environment
Write-Host "`n=== CLEANING ENVIRONMENT ===" -ForegroundColor Yellow
Remove-Module GA-AppLocker* -Force -ErrorAction SilentlyContinue
$env:PSModulePath = $env:PSModulePath -replace [regex]::Escape((Get-Location).Path), ''

# Import module fresh
Write-Host "`n=== IMPORTING MODULE ===" -ForegroundColor Yellow
$modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
Import-Module $modulePath -Force -ErrorAction Stop
Write-Host "Module imported successfully" -ForegroundColor Green

# Test 1: Storage module functions are accessible
Test-Diagnostic "Storage: Write-StorageLog is callable" {
    # This should NOT throw "term not recognized"
    $testRule = @{
        Id = [guid]::NewGuid().ToString()
        Name = "Diagnostic Test Rule"
        RuleType = "Hash"
        CollectionType = "Exe"
        Status = "Pending"
        Action = "Allow"
        UserOrGroupSid = "S-1-1-0"
        Hash = ([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N'))
        CreatedDate = (Get-Date -Format 'o')
    }
    
    $result = Save-RulesBulk -Rules @($testRule)
    if (-not $result.Success) {
        throw "Save-RulesBulk failed: $($result.Error)"
    }
    
    # Clean up
    Remove-Rule -RuleId $testRule.Id -ErrorAction SilentlyContinue | Out-Null
}

# Test 2: Initialize-JsonIndex is accessible internally
Test-Diagnostic "Storage: Initialize-JsonIndex is accessible from BulkOperations" {
    # This tests that BulkOperations.ps1 can call Initialize-JsonIndex
    # If it can't, Save-RulesBulk would fail
    $testRule = @{
        Id = [guid]::NewGuid().ToString()
        Name = "Diagnostic Test Rule 2"
        RuleType = "Hash"
        CollectionType = "Exe"
        Status = "Pending"
        Action = "Allow"
        UserOrGroupSid = "S-1-1-0"
        Hash = ([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N'))
        CreatedDate = (Get-Date -Format 'o')
    }
    
    $result = Save-RulesBulk -Rules @($testRule)
    if (-not $result.Success) {
        throw "Save-RulesBulk failed (Initialize-JsonIndex not accessible): $($result.Error)"
    }
    
    # Clean up
    Remove-Rule -RuleId $testRule.Id -ErrorAction SilentlyContinue | Out-Null
}

# Test 3: Get-LocalArtifacts doesn't throw immediately
Test-Diagnostic "Scanning: Get-LocalArtifacts runs without immediate exception" {
    # Test with a safe path that definitely exists
    $testPath = $env:TEMP
    
    $result = Get-LocalArtifacts -Paths @($testPath) -Recurse:$false -ErrorAction Stop
    
    if ($result.Error -match "Access is denied") {
        throw "Get-LocalArtifacts threw Access Denied on $testPath"
    }
    
    # Should return a result object even if no files found
    if ($null -eq $result) {
        throw "Get-LocalArtifacts returned null"
    }
}

# Test 4: Scanning finds non-Appx files
Test-Diagnostic "Scanning: Get-LocalArtifacts finds EXE files" {
    # Scan System32 which definitely has EXE files
    $result = Get-LocalArtifacts -Paths @('C:\Windows\System32') -Recurse:$false -ErrorAction Stop
    
    if ($result.Error) {
        throw "Scan failed: $($result.Error)"
    }
    
    if (-not $result.Data -or $result.Data.Count -eq 0) {
        throw "No artifacts found in System32 (should find many EXE files)"
    }
    
    $exeFiles = @($result.Data | Where-Object { $_.ArtifactType -eq 'EXE' })
    if ($exeFiles.Count -eq 0) {
        throw "No EXE files found in System32 (found only: $($result.Data | Group-Object ArtifactType | ForEach-Object { "$($_.Name):$($_.Count)" } | Join-String -Separator ', '))"
    }
    
    Write-Host "  Found $($exeFiles.Count) EXE files in System32" -ForegroundColor Gray
}

# Test 5: Module version is correct
Test-Diagnostic "Module: Version is 1.2.60" {
    $module = Get-Module GA-AppLocker
    if ($module.Version.ToString() -ne '1.2.60') {
        throw "Module version is $($module.Version), expected 1.2.60"
    }
}

# Test 6: GUI functions are defined (if GUI is loaded)
Test-Diagnostic "GUI: Core functions are defined" {
    # These should be global: functions if GUI is loaded
    # If not loaded, this test will fail (expected in non-GUI context)
    
    $guiPath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GUI\MainWindow.xaml.ps1'
    if (Test-Path $guiPath) {
        # Dot-source the GUI file to load functions
        . $guiPath
        
        # Check if Invoke-ButtonAction exists
        if (-not (Get-Command Invoke-ButtonAction -ErrorAction SilentlyContinue)) {
            throw "Invoke-ButtonAction not defined after loading MainWindow.xaml.ps1"
        }
    }
    else {
        Write-Host "  (Skipped - GUI files not in test context)" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Yellow
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { 'Green' } else { 'Red' })

if ($testsFailed -gt 0) {
    Write-Host "`nFAILURES:" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host "  - $($failure.Name)" -ForegroundColor Red
        Write-Host "    $($failure.Error)" -ForegroundColor Gray
    }
    exit 1
}
else {
    Write-Host "`nALL TESTS PASSED" -ForegroundColor Green
    exit 0
}
