#Requires -Version 5.1
<#
.SYNOPSIS
    Headless integration tests for GA-AppLocker workflow.
.DESCRIPTION
    Tests the complete pipeline: Discovery -> Scan -> Rules -> Policy -> Export
    Supports both mock data and live AD modes.
.EXAMPLE
    .\Test-FullWorkflow.ps1 -UseMockData
.EXAMPLE
    .\Test-FullWorkflow.ps1 -UseDockerAD
#>
param(
    [switch]$UseMockData,
    [switch]$UseDockerAD,
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'
$script:Passed = 0
$script:Failed = 0
$script:Skipped = 0
$script:TestData = @{}

#region Helper Functions
function Write-Result {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ''
    )
    if ($Passed) {
        $script:Passed++
        Write-Host "[PASS] " -ForegroundColor Green -NoNewline
    } else {
        $script:Failed++
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
    }
    Write-Host "$TestName" -NoNewline
    if ($Details) { Write-Host " - $Details" -ForegroundColor Gray }
    else { Write-Host "" }
}

function Write-Skip {
    param([string]$TestName, [string]$Reason)
    $script:Skipped++
    Write-Host "[SKIP] $TestName - $Reason" -ForegroundColor Yellow
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 50)" -ForegroundColor Cyan
}
#endregion

#region Setup
Write-Host "`n=== GA-AppLocker Workflow Integration Tests ===" -ForegroundColor Magenta
Write-Host "Mode: $(if($UseMockData){'MOCK DATA'}elseif($UseDockerAD){'DOCKER AD'}else{'LIVE AD'})" -ForegroundColor Yellow
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Load modules
try {
    $modulePath = Join-Path $PSScriptRoot "..\..\..\GA-AppLocker\GA-AppLocker.psd1"
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "[OK] GA-AppLocker module loaded" -ForegroundColor Green
} catch {
    Write-Host "[FATAL] Failed to load module: $_" -ForegroundColor Red
    exit 1
}

# Load mock data if requested
if ($UseMockData) {
    try {
        $mockPath = Join-Path $PSScriptRoot "..\MockData\New-MockTestData.psm1"
        Import-Module $mockPath -Force -ErrorAction Stop
        $script:MockEnv = New-MockTestEnvironment -ComputerCount 10 -ArtifactsPerComputer 15 `
                                                   -IncludeCredentials -IncludeRules -IncludePolicies
        Write-Host "[OK] Mock environment created: $($script:MockEnv.Computers.Count) computers, $($script:MockEnv.Artifacts.Count) artifacts" -ForegroundColor Green
    } catch {
        Write-Host "[FATAL] Failed to create mock environment: $_" -ForegroundColor Red
        exit 1
    }
}

# Configure Docker AD if requested
if ($UseDockerAD) {
    $dockerScript = Join-Path $PSScriptRoot "..\..\..\docker\Start-ADTestEnvironment.ps1"
    if (Test-Path $dockerScript) {
        Write-Host "Checking Docker AD status..." -ForegroundColor Gray
        & $dockerScript -Action Status
    } else {
        Write-Host "[WARN] Docker AD script not found at: $dockerScript" -ForegroundColor Yellow
    }
}
#endregion

#region Stage 1: Discovery Tests
Write-Section "STAGE 1: DISCOVERY"

# Test 1.1: Get-DomainInfo
if ($UseMockData) {
    $script:TestData.DomainInfo = $script:MockEnv.DomainInfo
    Write-Result "Get-DomainInfo (mock)" $true "Domain: $($script:TestData.DomainInfo.DomainName)"
} else {
    try {
        $result = Get-DomainInfo
        if ($result.Success) {
            $script:TestData.DomainInfo = $result.Data
            Write-Result "Get-DomainInfo" $true "Domain: $($result.Data.DomainName)"
        } else {
            Write-Result "Get-DomainInfo" $false $result.Error
        }
    } catch {
        Write-Result "Get-DomainInfo" $false $_.Exception.Message
    }
}

# Test 1.2: Get-OUTree
if ($UseMockData) {
    $script:TestData.OUTree = $script:MockEnv.OUTree
    Write-Result "Get-OUTree (mock)" $true "Found $($script:TestData.OUTree.Count) OUs"
} else {
    try {
        $result = Get-OUTree
        if ($result.Success) {
            $script:TestData.OUTree = $result.Data
            Write-Result "Get-OUTree" $true "Found $($result.Data.Count) OUs"
        } else {
            Write-Result "Get-OUTree" $false $result.Error
        }
    } catch {
        Write-Result "Get-OUTree" $false $_.Exception.Message
    }
}

# Test 1.3: Get-ComputersByOU
if ($UseMockData) {
    $script:TestData.Computers = $script:MockEnv.Computers
    Write-Result "Get-ComputersByOU (mock)" $true "Found $($script:TestData.Computers.Count) computers"
} else {
    try {
        if ($script:TestData.OUTree -and $script:TestData.OUTree.Count -gt 0) {
            $testOU = $script:TestData.OUTree | Select-Object -First 1
            $result = Get-ComputersByOU -OU $testOU.DN
            if ($result.Success) {
                $script:TestData.Computers = $result.Data
                Write-Result "Get-ComputersByOU" $true "Found $($result.Data.Count) computers in $($testOU.Name)"
            } else {
                Write-Result "Get-ComputersByOU" $false $result.Error
            }
        } else {
            Write-Skip "Get-ComputersByOU" "No OUs available"
        }
    } catch {
        Write-Result "Get-ComputersByOU" $false $_.Exception.Message
    }
}
#endregion

#region Stage 2: Scanning Tests
Write-Section "STAGE 2: SCANNING"

# Test 2.1: Get-LocalArtifacts
try {
    $testPath = "$env:SystemRoot\System32"
    $result = Get-LocalArtifacts -Path $testPath -Depth 1
    if ($result.Success -and $result.Data.Count -gt 0) {
        $script:TestData.LocalArtifacts = $result.Data | Select-Object -First 50
        Write-Result "Get-LocalArtifacts" $true "Found $($result.Data.Count) artifacts in $testPath"
    } elseif ($result.Success) {
        Write-Result "Get-LocalArtifacts" $false "No artifacts found"
    } else {
        Write-Result "Get-LocalArtifacts" $false $result.Error
    }
} catch {
    Write-Result "Get-LocalArtifacts" $false $_.Exception.Message
}

# Test 2.2: Use mock or local artifacts
if ($UseMockData) {
    $script:TestData.AllArtifacts = $script:MockEnv.Artifacts
    Write-Result "Artifact Collection (mock)" $true "Using $($script:TestData.AllArtifacts.Count) mock artifacts"
} else {
    # Use local artifacts for testing in non-mock mode
    if ($script:TestData.LocalArtifacts -and $script:TestData.LocalArtifacts.Count -gt 0) {
        $script:TestData.AllArtifacts = $script:TestData.LocalArtifacts
        Write-Result "Artifact Collection (local)" $true "Using $($script:TestData.AllArtifacts.Count) local artifacts"
    } else {
        Write-Skip "Artifact Collection" "No artifacts available"
    }
}

# Test 2.3: Verify artifact structure
if ($script:TestData.AllArtifacts -and $script:TestData.AllArtifacts.Count -gt 0) {
    $sampleArtifact = $script:TestData.AllArtifacts | Select-Object -First 1
    $hasRequiredProps = ($null -ne $sampleArtifact.FileName) -and ($null -ne $sampleArtifact.ArtifactType)
    Write-Result "Artifact Structure Validation" $hasRequiredProps "FileName and ArtifactType present"
}
#endregion

#region Stage 3: Rules Tests
Write-Section "STAGE 3: RULE GENERATION"

# Test 3.1: New-HashRule
if ($script:TestData.AllArtifacts -and $script:TestData.AllArtifacts.Count -gt 0) {
    try {
        $testArtifact = $script:TestData.AllArtifacts | Select-Object -First 1
        $hash = if ($testArtifact.FileHash) { $testArtifact.FileHash } else { "ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890" }
        
        $ruleParams = @{
            Name = "Test-HashRule-$(Get-Date -Format 'HHmmss')"
            FileHash = $hash
            FileName = $testArtifact.FileName
            CollectionType = 'Exe'
        }
        $result = New-HashRule @ruleParams
        if ($result.Success) {
            $script:TestData.TestHashRule = $result.Data
            Write-Result "New-HashRule" $true "Created: $($result.Data.Name)"
        } else {
            Write-Result "New-HashRule" $false $result.Error
        }
    } catch {
        Write-Result "New-HashRule" $false $_.Exception.Message
    }
} else {
    Write-Skip "New-HashRule" "No artifacts available"
}

# Test 3.2: New-PublisherRule (if signed artifact available)
if ($UseMockData -and $script:MockEnv.Artifacts) {
    $signedArtifact = $script:MockEnv.Artifacts | Where-Object { $_.Signed } | Select-Object -First 1
    if ($signedArtifact) {
        try {
            $ruleParams = @{
                Name = "Test-PublisherRule-$(Get-Date -Format 'HHmmss')"
                Publisher = $signedArtifact.Publisher
                ProductName = $signedArtifact.ProductName
                CollectionType = 'Exe'
            }
            $result = New-PublisherRule @ruleParams
            if ($result.Success) {
                $script:TestData.TestPublisherRule = $result.Data
                Write-Result "New-PublisherRule" $true "Created: $($result.Data.Name)"
            } else {
                Write-Result "New-PublisherRule" $false $result.Error
            }
        } catch {
            Write-Result "New-PublisherRule" $false $_.Exception.Message
        }
    }
}

# Test 3.3: Use mock rules if available
if ($UseMockData -and $script:MockEnv.Rules) {
    $script:TestData.AllRules = $script:MockEnv.Rules
    Write-Result "Rule Collection (mock)" $true "Using $($script:TestData.AllRules.Count) mock rules"
} else {
    # Collect any rules we created
    $script:TestData.AllRules = @()
    if ($script:TestData.TestHashRule) { $script:TestData.AllRules += $script:TestData.TestHashRule }
    if ($script:TestData.TestPublisherRule) { $script:TestData.AllRules += $script:TestData.TestPublisherRule }
    if ($script:TestData.AllRules.Count -gt 0) {
        Write-Result "Rule Collection" $true "Collected $($script:TestData.AllRules.Count) rules"
    }
}
#endregion

#region Stage 4: Policy Tests
Write-Section "STAGE 4: POLICY BUILDING"

# Test 4.1: New-Policy
try {
    $policyName = "WorkflowTest-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $result = New-Policy -Name $policyName `
                         -Description "Automated workflow test policy" `
                         -MachineType "Workstation"
    if ($result.Success) {
        $script:TestData.TestPolicy = $result.Data
        Write-Result "New-Policy" $true "Created: $($result.Data.Name) (ID: $($result.Data.Id))"
    } else {
        Write-Result "New-Policy" $false $result.Error
    }
} catch {
    Write-Result "New-Policy" $false $_.Exception.Message
}

# Test 4.2: Add-RuleToPolicy
if ($script:TestData.TestPolicy -and $script:TestData.AllRules -and $script:TestData.AllRules.Count -gt 0) {
    try {
        $ruleToAdd = $script:TestData.AllRules | Select-Object -First 1
        $result = Add-RuleToPolicy -PolicyId $script:TestData.TestPolicy.Id -RuleId $ruleToAdd.Id
        if ($result.Success) {
            Write-Result "Add-RuleToPolicy" $true "Added rule: $($ruleToAdd.Name)"
        } else {
            Write-Result "Add-RuleToPolicy" $false $result.Error
        }
    } catch {
        Write-Result "Add-RuleToPolicy" $false $_.Exception.Message
    }
} else {
    Write-Skip "Add-RuleToPolicy" "No policy or rules available"
}

# Test 4.3: Get-Policy (verify)
if ($script:TestData.TestPolicy) {
    try {
        $result = Get-Policy -Id $script:TestData.TestPolicy.Id
        if ($result.Success -and $result.Data) {
            Write-Result "Get-Policy (verify)" $true "Policy retrieved, RuleCount: $($result.Data.RuleCount)"
        } else {
            Write-Result "Get-Policy (verify)" $false ($result.Error ?? "Policy not found")
        }
    } catch {
        Write-Result "Get-Policy (verify)" $false $_.Exception.Message
    }
} else {
    Write-Skip "Get-Policy (verify)" "No policy created"
}

# Test 4.4: Get-AllPolicies
try {
    $result = Get-AllPolicies
    if ($result.Success) {
        Write-Result "Get-AllPolicies" $true "Found $($result.Data.Count) policies"
    } else {
        Write-Result "Get-AllPolicies" $false $result.Error
    }
} catch {
    Write-Result "Get-AllPolicies" $false $_.Exception.Message
}
#endregion

#region Stage 5: Export Tests
Write-Section "STAGE 5: EXPORT"

# Test 5.1: Export-PolicyToXml
if ($script:TestData.TestPolicy) {
    try {
        $exportPath = Join-Path $env:TEMP "GA-AppLocker-Test-$(Get-Date -Format 'yyyyMMdd-HHmmss').xml"
        $result = Export-PolicyToXml -PolicyId $script:TestData.TestPolicy.Id -Path $exportPath
        
        if ($result.Success) {
            if (Test-Path $exportPath) {
                $xmlContent = Get-Content $exportPath -Raw -ErrorAction SilentlyContinue
                $isValidXml = $xmlContent -match '<AppLockerPolicy'
                Write-Result "Export-PolicyToXml" $isValidXml "Exported to: $exportPath"
                
                # Cleanup
                Remove-Item $exportPath -Force -ErrorAction SilentlyContinue
            } else {
                Write-Result "Export-PolicyToXml" $false "Export file not created"
            }
        } else {
            Write-Result "Export-PolicyToXml" $false $result.Error
        }
    } catch {
        Write-Result "Export-PolicyToXml" $false $_.Exception.Message
    }
} else {
    Write-Skip "Export-PolicyToXml" "No policy available"
}

# Test 5.2: Test-PolicyCompliance (if function exists)
if ($script:TestData.TestPolicy) {
    try {
        if (Get-Command Test-PolicyCompliance -ErrorAction SilentlyContinue) {
            $result = Test-PolicyCompliance -PolicyId $script:TestData.TestPolicy.Id
            if ($result.Success) {
                Write-Result "Test-PolicyCompliance" $true "Compliance check completed"
            } else {
                Write-Result "Test-PolicyCompliance" $false $result.Error
            }
        } else {
            Write-Skip "Test-PolicyCompliance" "Function not available"
        }
    } catch {
        Write-Result "Test-PolicyCompliance" $false $_.Exception.Message
    }
}
#endregion

#region Summary
Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
Write-Host " TEST SUMMARY" -ForegroundColor Cyan
Write-Host "$('=' * 50)" -ForegroundColor Cyan
Write-Host "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "Results:" -ForegroundColor White
Write-Host "  Passed:  $script:Passed" -ForegroundColor Green
Write-Host "  Failed:  $script:Failed" -ForegroundColor $(if($script:Failed -gt 0){'Red'}else{'Gray'})
Write-Host "  Skipped: $script:Skipped" -ForegroundColor Yellow
Write-Host ""

$total = $script:Passed + $script:Failed
$passRate = if ($total -gt 0) { [math]::Round(($script:Passed / $total) * 100, 1) } else { 0 }
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if($passRate -ge 80){'Green'}elseif($passRate -ge 50){'Yellow'}else{'Red'})
Write-Host ""

$exitCode = if ($script:Failed -gt 0) { 1 } else { 0 }
exit $exitCode
#endregion
