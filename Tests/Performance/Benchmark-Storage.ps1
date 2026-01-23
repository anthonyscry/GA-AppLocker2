<#
.SYNOPSIS
    Performance benchmarks for GA-AppLocker Storage operations.

.DESCRIPTION
    Measures performance of key storage operations to ensure
    they meet acceptable thresholds.

.NOTES
    Run with: .\Tests\Performance\Benchmark-Storage.ps1
    
    Expected performance targets:
    - Index build (35k rules): < 60 seconds
    - Single hash lookup: < 10ms
    - Paginated query (1000 rules): < 100ms
    - Cache hit: < 1ms
#>

param(
    [Parameter()]
    [int]$RuleCount = 1000,  # Number of test rules to create

    [Parameter()]
    [switch]$SkipCleanup,

    [Parameter()]
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

# Import module
$modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
Import-Module $modulePath -Force

Write-Host "`n" -NoNewline
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host " GA-AppLocker Storage Performance Benchmarks" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Measure-Operation {
    param(
        [string]$Name,
        [scriptblock]$Operation,
        [int]$Iterations = 1,
        [double]$TargetMs = 0
    )

    $timings = [System.Collections.Generic.List[double]]::new()
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & $Operation | Out-Null
        $sw.Stop()
        $timings.Add($sw.Elapsed.TotalMilliseconds)
    }

    $avg = ($timings | Measure-Object -Average).Average
    $min = ($timings | Measure-Object -Minimum).Minimum
    $max = ($timings | Measure-Object -Maximum).Maximum

    $status = if ($TargetMs -gt 0 -and $avg -le $TargetMs) { 
        Write-Host "[PASS] " -ForegroundColor Green -NoNewline
        'PASS'
    } elseif ($TargetMs -gt 0) {
        Write-Host "[SLOW] " -ForegroundColor Yellow -NoNewline
        'SLOW'
    } else {
        Write-Host "[    ] " -ForegroundColor Gray -NoNewline
        'N/A'
    }

    Write-Host "$Name" -NoNewline
    Write-Host " - Avg: $([math]::Round($avg, 2))ms" -ForegroundColor Gray -NoNewline
    if ($Iterations -gt 1) {
        Write-Host " (Min: $([math]::Round($min, 2))ms, Max: $([math]::Round($max, 2))ms)" -ForegroundColor DarkGray -NoNewline
    }
    if ($TargetMs -gt 0) {
        Write-Host " [Target: ${TargetMs}ms]" -ForegroundColor DarkGray -NoNewline
    }
    Write-Host ""

    $results.Add([PSCustomObject]@{
        Name = $Name
        AvgMs = [math]::Round($avg, 2)
        MinMs = [math]::Round($min, 2)
        MaxMs = [math]::Round($max, 2)
        TargetMs = $TargetMs
        Status = $status
        Iterations = $Iterations
    })
}

#region ===== SETUP =====
Write-Host "`nSetting up test data ($RuleCount rules)..." -ForegroundColor Yellow

$testRuleIds = [System.Collections.Generic.List[string]]::new()
$testHashes = [System.Collections.Generic.List[string]]::new()

# Create test rules in batches
$batchSize = 100
$batches = [math]::Ceiling($RuleCount / $batchSize)

for ($b = 0; $b -lt $batches; $b++) {
    $startIdx = $b * $batchSize
    $endIdx = [math]::Min(($b + 1) * $batchSize - 1, $RuleCount - 1)
    
    for ($i = $startIdx; $i -le $endIdx; $i++) {
        $hash = '{0:X64}' -f $i
        $rule = [PSCustomObject]@{
            RuleId = "perf-test-$i"
            Name = "PerfTestRule$i"
            RuleType = 'Hash'
            Status = @('Pending', 'Approved', 'Rejected')[$i % 3]
            CollectionType = @('Exe', 'Dll', 'Msi')[$i % 3]
            Action = 'Allow'
            Hash = $hash
            CreatedDate = (Get-Date).AddDays(-$i).ToString('o')
        }
        Add-RuleToDatabase -Rule $rule | Out-Null
        $testRuleIds.Add($rule.RuleId)
        $testHashes.Add($hash)
    }
    
    Write-Progress -Activity "Creating test rules" -PercentComplete (($b + 1) / $batches * 100)
}
Write-Progress -Activity "Creating test rules" -Completed

Write-Host "Created $RuleCount test rules`n" -ForegroundColor Green
#endregion

#region ===== BENCHMARKS =====
Write-Host "Running benchmarks...`n" -ForegroundColor Yellow

# 1. Database initialization (rebuild index)
Measure-Operation -Name "Index Rebuild" -Operation {
    Initialize-RuleDatabase -Force
} -TargetMs 60000  # 60 seconds for full rebuild

# 2. Single hash lookup
$randomHash = $testHashes[(Get-Random -Maximum $testHashes.Count)]
Measure-Operation -Name "Hash Lookup (single)" -Operation {
    Find-RuleByHash -Hash $randomHash
} -Iterations 10 -TargetMs 10

# 3. Get rule by ID
$randomId = $testRuleIds[(Get-Random -Maximum $testRuleIds.Count)]
Measure-Operation -Name "Get Rule by ID" -Operation {
    Get-RuleFromDatabase -RuleId $randomId
} -Iterations 10 -TargetMs 10

# 4. Paginated query (first page)
Measure-Operation -Name "Query First 100 Rules" -Operation {
    Get-RulesFromDatabase -Take 100 -Skip 0
} -Iterations 5 -TargetMs 100

# 5. Paginated query with filter
Measure-Operation -Name "Query 100 Pending Rules" -Operation {
    Get-RulesFromDatabase -Status 'Pending' -Take 100
} -Iterations 5 -TargetMs 150

# 6. Get rule counts
Measure-Operation -Name "Get Rule Counts" -Operation {
    Get-RuleCounts
} -Iterations 5 -TargetMs 50

# 7. Cache performance
Clear-AppLockerCache | Out-Null
Set-CachedValue -Key 'PerfTestKey' -Value @{ Data = 'Test' * 100 }

Measure-Operation -Name "Cache Hit" -Operation {
    Get-CachedValue -Key 'PerfTestKey'
} -Iterations 100 -TargetMs 1

# 8. Repository with caching
Clear-AppLockerCache | Out-Null
$testId = $testRuleIds[0]

Measure-Operation -Name "Repository Get (cold)" -Operation {
    Clear-AppLockerCache -Key "Rule_$testId"
    Get-RuleFromRepository -RuleId $testId
} -Iterations 5 -TargetMs 15

Measure-Operation -Name "Repository Get (warm)" -Operation {
    Get-RuleFromRepository -RuleId $testId
} -Iterations 10 -TargetMs 2

# 9. Bulk update
$batchIds = $testRuleIds | Select-Object -First 50
Measure-Operation -Name "Bulk Update 50 Rules" -Operation {
    Invoke-RuleBatchOperation -RuleIds $batchIds -Operation 'UpdateStatus' -Parameters @{ Status = 'Approved' }
} -TargetMs 500

# 10. Find with complex filter
Measure-Operation -Name "Find with Filter (pattern)" -Operation {
    Find-RulesInRepository -Filter @{ Status = 'Pending' } -Take 100 -BypassCache
} -Iterations 3 -TargetMs 200

#endregion

#region ===== CLEANUP =====
if (-not $SkipCleanup) {
    Write-Host "`nCleaning up test data..." -ForegroundColor Yellow
    
    $deleteCount = 0
    foreach ($id in $testRuleIds) {
        Remove-RuleFromDatabase -RuleId $id -ErrorAction SilentlyContinue | Out-Null
        $deleteCount++
        if ($deleteCount % 100 -eq 0) {
            Write-Progress -Activity "Cleaning up" -PercentComplete ($deleteCount / $testRuleIds.Count * 100)
        }
    }
    Write-Progress -Activity "Cleaning up" -Completed
    
    # Rebuild index after cleanup
    Initialize-RuleDatabase -Force | Out-Null
    
    Write-Host "Cleanup complete`n" -ForegroundColor Green
}
#endregion

#region ===== SUMMARY =====
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host " Benchmark Summary" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$passed = ($results | Where-Object { $_.Status -eq 'PASS' }).Count
$slow = ($results | Where-Object { $_.Status -eq 'SLOW' }).Count
$total = ($results | Where-Object { $_.TargetMs -gt 0 }).Count

Write-Host "`nResults: " -NoNewline
Write-Host "$passed passed" -ForegroundColor Green -NoNewline
Write-Host ", " -NoNewline
Write-Host "$slow slow" -ForegroundColor Yellow -NoNewline
Write-Host " out of $total benchmarks with targets`n"

if ($Verbose) {
    Write-Host "`nDetailed Results:" -ForegroundColor Yellow
    $results | Format-Table -AutoSize
}

# Return results for programmatic use
return $results
#endregion
