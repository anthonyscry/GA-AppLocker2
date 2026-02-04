param(
    [int]$Count = 1000,
    [string]$Prefix = 'PerfPolicy',
    [int]$Phase = 1,
    [string]$Description = 'Performance test policy',
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'GA-AppLocker\GA-AppLocker.psd1'
if (-not (Test-Path $modulePath)) {
    Write-Error "Module not found at $modulePath"
    exit 1
}

Import-Module $modulePath -Force

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$created = 0
$failed = 0

for ($i = 1; $i -le $Count; $i++) {
    $suffix = [guid]::NewGuid().ToString('N').Substring(0, 8)
    $policyName = "{0}-{1:0000}-{2}" -f $Prefix, $i, $suffix
    $desc = "$Description $i"

    try {
        $result = New-Policy -Name $policyName -Description $desc -Phase $Phase
        if ($result.Success) {
            $created++
        }
        else {
            $failed++
            if ($VerboseOutput) {
                Write-Host "Failed: $policyName -> $($result.Error)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        $failed++
        if ($VerboseOutput) {
            Write-Host "Failed: $policyName -> $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($i % 50 -eq 0) {
        Write-Host "Created $created/$i policies..."
    }
}

$stopwatch.Stop()

Write-Host "Completed. Created: $created. Failed: $failed. Duration: $($stopwatch.Elapsed.TotalSeconds.ToString('F1'))s"
