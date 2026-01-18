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
    [switch]$Quick
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
if (-not $pester -or $pester.Version -lt [version]'5.0.0') {
    Write-Host "[WARN] Pester 5+ not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    Import-Module Pester -Force
} else {
    Import-Module Pester -Force
}

# Paths
$projectRoot = Split-Path -Parent $PSScriptRoot
$testsPath = $PSScriptRoot
$modulePath = Join-Path $projectRoot 'GA-AppLocker'

Write-Host "Project Root: $projectRoot" -ForegroundColor Gray
Write-Host "Tests Path:   $testsPath" -ForegroundColor Gray
Write-Host ""

# Build Pester configuration
$config = New-PesterConfiguration
$config.Run.Path = $testsPath
$config.Run.Exit = $false
$config.Output.Verbosity = 'Detailed'

if ($Tag) {
    $config.Filter.Tag = $Tag
    Write-Host "Filter: Tags = $($Tag -join ', ')" -ForegroundColor Yellow
}

if ($ExcludeTag) {
    $config.Filter.ExcludeTag = $ExcludeTag
    Write-Host "Filter: ExcludeTags = $($ExcludeTag -join ', ')" -ForegroundColor Yellow
}

if ($Quick) {
    $config.Filter.Tag = @('Unit')
    Write-Host "Quick Mode: Running Unit tests only" -ForegroundColor Yellow
}

if ($Coverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        "$modulePath\Modules\GA-AppLocker.Policy\Functions\*.ps1",
        "$modulePath\Modules\GA-AppLocker.Rules\Functions\*.ps1"
    )
    $config.CodeCoverage.OutputPath = Join-Path $projectRoot 'coverage.xml'
    Write-Host "Code Coverage: Enabled" -ForegroundColor Yellow
}

if ($OutputPath) {
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = $OutputPath
    $config.TestResult.OutputFormat = 'NUnitXml'
    Write-Host "Test Results: $OutputPath" -ForegroundColor Yellow
}

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
# PHASE 2: Pester Unit Tests
# ============================================================
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  PHASE 2: Pester Tests" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$pesterResult = Invoke-Pester -Configuration $config

if ($pesterResult.FailedCount -gt 0) {
    Write-Host "`n[FAIL] $($pesterResult.FailedCount) Pester test(s) failed" -ForegroundColor Red
    $script:exitCode = 1
} else {
    Write-Host "`n[PASS] All $($pesterResult.PassedCount) Pester tests passed" -ForegroundColor Green
}

Write-Host ""

# ============================================================
# PHASE 3: Legacy Test Suite (if not Quick mode)
# ============================================================
if (-not $Quick) {
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
