#Requires -Version 5.1
<#
.SYNOPSIS
    Master test runner for GA-AppLocker test suite.

.DESCRIPTION
    Runs all Pester tests and the legacy Test-AllModules.ps1 suite.
    Supports filtering by tag and generating code coverage reports.

.PARAMETER Tag
    Run only tests with specified tags (e.g., 'Unit', 'Integration', 'Phase').

.PARAMETER ExcludeTag
    Exclude tests with specified tags.

.PARAMETER Coverage
    Generate code coverage report.

.PARAMETER OutputPath
    Path for test results file (NUnit format).

.PARAMETER Quick
    Run only unit tests for fast feedback.

.EXAMPLE
    .\Tests\Run-AllTests.ps1
    Runs all tests.

.EXAMPLE
    .\Tests\Run-AllTests.ps1 -Tag 'Unit' -Quick
    Runs only unit tests for fast feedback.

.EXAMPLE
    .\Tests\Run-AllTests.ps1 -Coverage
    Runs all tests with code coverage report.
#>
[CmdletBinding()]
param(
    [string[]]$Tag,
    [string[]]$ExcludeTag,
    [switch]$Coverage,
    [string]$OutputPath,
    [switch]$Quick,
    [switch]$Legacy,
    [switch]$MustPass
)

$ErrorActionPreference = 'Stop'
$script:exitCode = 0

# Banner
Write-Host "`n" -NoNewline
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  GA-AppLocker Test Suite" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Check for Pester
$pester = Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
$pesterVersion = $pester.Version

Write-Host "Detected Pester version: $pesterVersion" -ForegroundColor Cyan

# Paths
$projectRoot = Split-Path -Parent $PSScriptRoot
$testsPath = Join-Path $PSScriptRoot 'Behavioral'
$modulePath = Join-Path $projectRoot 'GA-AppLocker'
$mustPassTests = @(
    (Join-Path $PSScriptRoot 'Behavioral\Workflows\CoreFlows.E2E.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Behavioral\Core\Rules.Behavior.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Behavioral\Core\Policy.Behavior.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Behavioral\GUI\RecentRegressions.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Behavioral\GUI\ADDiscovery.AutoRefresh.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Behavioral\GUI\Dashboard.WinRMButton.Tests.ps1')
)

Write-Host "Project Root: $projectRoot" -ForegroundColor Gray
Write-Host "Tests Path:   $testsPath" -ForegroundColor Gray
Write-Host ""

# Build Pester 3.4 compatible parameters
# Note: Pester 3.4 does not use -Configuration parameter
# Use script paths and switches directly
$invokePesterParams = @{}

# Build parameters dynamically (default run is curated high-signal gate)
$missingMustPass = @($mustPassTests | Where-Object { -not (Test-Path $_) })
if ($missingMustPass.Count -gt 0) {
    throw "Must-pass test files missing:`n$($missingMustPass -join "`n")"
}

$invokePesterParams['Script'] = @($mustPassTests)
if ($MustPass) {
    Write-Host "MustPass Mode: Running curated high-signal gate ($($mustPassTests.Count) files)" -ForegroundColor Yellow
}
elseif (-not $Quick -and -not $Legacy) {
    Write-Host "Default Mode: Running curated high-signal gate ($($mustPassTests.Count) files)" -ForegroundColor Yellow
}

if ($Tag) {
    $invokePesterParams['Tag'] = $Tag
    Write-Host "Filter: Tags = $($Tag -join ', ')" -ForegroundColor Yellow
}

if ($ExcludeTag) {
    $invokePesterParams['ExcludeTag'] = $ExcludeTag
    Write-Host "Filter: ExcludeTags = $($ExcludeTag -join ', ')" -ForegroundColor Yellow
}

if ($Quick -and -not $MustPass) {
    $invokePesterParams['Script'] = @($mustPassTests)
    Write-Host "Quick Mode: Running curated must-pass gate ($($mustPassTests.Count) files)" -ForegroundColor Yellow
}

if ($Legacy -and -not $MustPass) {
    $legacyPath = Join-Path $PSScriptRoot 'Legacy'
    $invokePesterParams['Script'] = @($testsPath, $legacyPath)
    Write-Host "Legacy Mode: Running Behavioral + Legacy tests" -ForegroundColor Yellow
}

if ($Coverage) {
    $invokePesterParams['CodeCoverage'] = $true
    # Cover all module Functions/ directories
    $coveragePaths = @()
    $modulesDir = Join-Path $modulePath 'Modules'
    $subModules = Get-ChildItem -Path $modulesDir -Directory -ErrorAction SilentlyContinue
    foreach ($mod in $subModules) {
        $funcDir = Join-Path $mod.FullName 'Functions'
        if (Test-Path $funcDir) {
            $coveragePaths += Join-Path $funcDir '*.ps1'
        }
    }
    $invokePesterParams['CodeCoveragePath'] = $coveragePaths
    $invokePesterParams['CodeCoverageOutputFile'] = Join-Path $projectRoot 'coverage.xml'
    $invokePesterParams['CodeCoverageOutputFormat'] = 'JaCoCo'
    Write-Host "Code Coverage: Enabled ($($coveragePaths.Count) module paths)" -ForegroundColor Yellow
}

if ($OutputPath) {
    $invokePesterParams['OutputFile'] = $OutputPath
    Write-Host "Test Results: $OutputPath" -ForegroundColor Yellow
}

# Always return PassThru result
$invokePesterParams['PassThru'] = $true

Write-Host ""

# ============================================================
# PHASE 1: PSScriptAnalyzer (Lint)
# ============================================================
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  PHASE 1: Static Analysis (PSScriptAnalyzer)" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$analyzerInstalled = Get-Module -Name PSScriptAnalyzer -ListAvailable
if ($analyzerInstalled) {
    Import-Module PSScriptAnalyzer -Force
    $settingsPath = Join-Path $projectRoot 'PSScriptAnalyzerSettings.psd1'
    
    if (Test-Path $settingsPath) {
        $analysisResults = Invoke-ScriptAnalyzer -Path $modulePath -Settings $settingsPath -Recurse -Severity Error, Warning
    } else {
        $analysisResults = Invoke-ScriptAnalyzer -Path $modulePath -Recurse -Severity Error, Warning
    }
    
    $errors = $analysisResults | Where-Object { $_.Severity -eq 'Error' }
    $warnings = $analysisResults | Where-Object { $_.Severity -eq 'Warning' }
    
    if ($errors.Count -gt 0) {
        Write-Host "[FAIL] $($errors.Count) error(s) found" -ForegroundColor Red
        $errors | ForEach-Object {
            Write-Host "  ERROR: $($_.ScriptName):$($_.Line) - $($_.Message)" -ForegroundColor Red
        }
        $script:exitCode = 1
    } else {
        Write-Host "[PASS] No errors found" -ForegroundColor Green
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "[WARN] $($warnings.Count) warning(s) found" -ForegroundColor Yellow
        $warnings | Select-Object -First 5 | ForEach-Object {
            Write-Host "  WARN: $($_.ScriptName):$($_.Line) - $($_.Message)" -ForegroundColor Yellow
        }
        if ($warnings.Count -gt 5) {
            Write-Host "  ... and $($warnings.Count - 5) more warnings" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[SKIP] PSScriptAnalyzer not installed" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================
# PHASE 2: Pester Unit Tests (Pester 3.4 compatible)
# ============================================================
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  PHASE 2: Pester Tests (Pester $pesterVersion)" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Invoke Pester with parameter hashtable (Pester 3.4 compatible)
# Note: -PassThru is required to get result object in Pester 3.4
$pesterResult = Invoke-Pester @invokePesterParams

if ($pesterResult.FailedCount -gt 0) {
    Write-Host "`n[FAIL] $($pesterResult.FailedCount) Pester test(s) failed" -ForegroundColor Red
    $script:exitCode = 1
} else {
    Write-Host "`n[PASS] All $($pesterResult.PassedCount) Pester tests passed" -ForegroundColor Green
}

Write-Host ""

# ============================================================
# PHASE 3: Legacy Test Suite (optional)
# ============================================================
if ($Legacy -and -not $MustPass) {
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  PHASE 3: Legacy Test Suite (Test-AllModules.ps1)" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan

    $legacyTestPath = Join-Path $projectRoot 'Test-AllModules.ps1'
    if (Test-Path $legacyTestPath) {
        try {
            & $legacyTestPath
            Write-Host "`n[PASS] Legacy test suite completed" -ForegroundColor Green
        }
        catch {
            Write-Host "`n[FAIL] Legacy test suite failed: $($_.Exception.Message)" -ForegroundColor Red
            $script:exitCode = 1
        }
    } else {
        Write-Host "[SKIP] Test-AllModules.ps1 not found" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================
# SUMMARY
# ============================================================
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

Write-Host "Pester Tests:  $($pesterResult.PassedCount) passed, $($pesterResult.FailedCount) failed, $($pesterResult.SkippedCount) skipped"

if ($Coverage) {
    $coveragePercent = [math]::Round(($pesterResult.CodeCoverage.CoveragePercent), 2)
    Write-Host "Code Coverage: $coveragePercent%"
}

Write-Host ""

if ($script:exitCode -eq 0) {
    Write-Host "[SUCCESS] All tests passed!" -ForegroundColor Green
} else {
    Write-Host "[FAILURE] Some tests failed. See above for details." -ForegroundColor Red
}

exit $script:exitCode
