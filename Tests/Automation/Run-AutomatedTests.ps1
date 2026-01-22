#Requires -Version 5.1
<#
.SYNOPSIS
    Unified test launcher for GA-AppLocker automated testing.
.DESCRIPTION
    Runs mock data generators, headless workflow tests, and/or UI automation.
    Provides comprehensive test coverage for GA-AppLocker functionality.
.PARAMETER All
    Run all test suites (Workflows + UI).
.PARAMETER Workflows
    Run workflow integration tests.
.PARAMETER UI
    Run UI automation tests.
.PARAMETER DockerAD
    Run Docker AD connectivity tests.
.PARAMETER UseMockData
    Use mock data instead of live AD for workflow tests.
.PARAMETER KeepUIOpen
    Don't close the dashboard after UI tests.
.PARAMETER UITestMode
    UI test mode: Quick, Standard, or Full.
.EXAMPLE
    .\Run-AutomatedTests.ps1 -All
.EXAMPLE
    .\Run-AutomatedTests.ps1 -Workflows -UseMockData
.EXAMPLE
    .\Run-AutomatedTests.ps1 -UI -KeepUIOpen
#>
param(
    [switch]$All,
    [switch]$Workflows,
    [switch]$UI,
    [switch]$DockerAD,
    [switch]$UseMockData,
    [switch]$KeepUIOpen,
    [ValidateSet('Quick', 'Standard', 'Full')]
    [string]$UITestMode = 'Standard'
)

$ErrorActionPreference = "Continue"
$script:StartTime = Get-Date
$script:WorkflowExit = 0
$script:UIExit = 0
$script:DockerExit = 0
$script:TestsRun = @()

# Header
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " GA-AppLocker Automated Test Runner" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Determine what to run
if ($All) {
    $Workflows = $true
    $UI = $true
    $DockerAD = $false  # Docker AD is opt-in only
}

if (-not $Workflows -and -not $UI -and -not $DockerAD) {
    $Workflows = $true  # Default to workflows if nothing specified
}

# Show test plan
Write-Host "Test Plan:" -ForegroundColor Yellow
if ($Workflows) {
    $mode = if ($UseMockData) { "MOCK DATA" } else { "LIVE AD" }
    Write-Host "  [x] Workflow Integration Tests ($mode)" -ForegroundColor Green
    $script:TestsRun += "Workflows"
}
if ($UI) {
    Write-Host "  [x] UI Automation Bot ($UITestMode mode)" -ForegroundColor Green
    $script:TestsRun += "UI"
}
if ($DockerAD) {
    Write-Host "  [x] Docker AD Connectivity Tests" -ForegroundColor Green
    $script:TestsRun += "DockerAD"
}
Write-Host ""

#region Run Workflow Tests
if ($Workflows) {
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host " WORKFLOW INTEGRATION TESTS" -ForegroundColor Magenta
    Write-Host "=============================================" -ForegroundColor Magenta
    
    $wfTest = Join-Path $PSScriptRoot "Workflows\Test-FullWorkflow.ps1"
    if (Test-Path $wfTest) {
        try {
            & $wfTest -UseMockData:$UseMockData
            $script:WorkflowExit = $LASTEXITCODE
        } catch {
            Write-Host "[ERROR] Workflow tests failed: $_" -ForegroundColor Red
            $script:WorkflowExit = 1
        }
    } else {
        Write-Host "[ERROR] Workflow test script not found: $wfTest" -ForegroundColor Red
        $script:WorkflowExit = 1
    }
}
#endregion

#region Run UI Automation Tests
if ($UI) {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host " UI AUTOMATION TESTS" -ForegroundColor Magenta
    Write-Host "=============================================" -ForegroundColor Magenta
    
    $uiTest = Join-Path $PSScriptRoot "UI\FlaUIBot.ps1"
    if (Test-Path $uiTest) {
        try {
            & $uiTest -TestMode $UITestMode -KeepOpen:$KeepUIOpen
            $script:UIExit = $LASTEXITCODE
        } catch {
            Write-Host "[ERROR] UI tests failed: $_" -ForegroundColor Red
            $script:UIExit = 1
        }
    } else {
        Write-Host "[ERROR] UI test script not found: $uiTest" -ForegroundColor Red
        $script:UIExit = 1
    }
}
#endregion

#region Run Docker AD Tests
if ($DockerAD) {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host " DOCKER AD CONNECTIVITY TESTS" -ForegroundColor Magenta
    Write-Host "=============================================" -ForegroundColor Magenta
    
    $adTest = Join-Path $PSScriptRoot "..\..\docker\Start-ADTestEnvironment.ps1"
    if (Test-Path $adTest) {
        try {
            & $adTest -Action Test
            $script:DockerExit = $LASTEXITCODE
        } catch {
            Write-Host "[ERROR] Docker AD tests failed: $_" -ForegroundColor Red
            $script:DockerExit = 1
        }
    } else {
        Write-Host "[WARN] Docker AD script not found: $adTest" -ForegroundColor Yellow
        Write-Host "       Docker AD tests are optional and require Docker to be installed." -ForegroundColor Gray
        $script:DockerExit = 0  # Don't fail if Docker isn't set up
    }
}
#endregion

#region Summary Report
$script:EndTime = Get-Date
$duration = $script:EndTime - $script:StartTime

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " AUTOMATED TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Duration: $([math]::Round($duration.TotalSeconds, 1)) seconds" -ForegroundColor Gray
Write-Host ""
Write-Host "Test Results:" -ForegroundColor White

if ($Workflows) {
    $wfStatus = if ($script:WorkflowExit -eq 0) { "PASSED" } else { "FAILED" }
    $wfColor = if ($script:WorkflowExit -eq 0) { "Green" } else { "Red" }
    Write-Host "  Workflow Tests:   $wfStatus" -ForegroundColor $wfColor
}

if ($UI) {
    $uiStatus = if ($script:UIExit -eq 0) { "PASSED" } else { "FAILED" }
    $uiColor = if ($script:UIExit -eq 0) { "Green" } else { "Red" }
    Write-Host "  UI Tests:         $uiStatus" -ForegroundColor $uiColor
}

if ($DockerAD) {
    $dockerStatus = if ($script:DockerExit -eq 0) { "PASSED" } else { "FAILED" }
    $dockerColor = if ($script:DockerExit -eq 0) { "Green" } else { "Red" }
    Write-Host "  Docker AD Tests:  $dockerStatus" -ForegroundColor $dockerColor
}

# Calculate overall result
$totalExit = $script:WorkflowExit + $script:UIExit + $script:DockerExit
$overallStatus = if ($totalExit -eq 0) { "PASSED" } else { "FAILED" }
$overallColor = if ($totalExit -eq 0) { "Green" } else { "Red" }

Write-Host ""
Write-Host "Overall Result: $overallStatus" -ForegroundColor $overallColor
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Exit with combined exit code
exit $totalExit
#endregion
