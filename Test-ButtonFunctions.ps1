<#
.SYNOPSIS
    Tests if the button handler functions exist and are callable.
#>

# Load the module first
Import-Module ".\GA-AppLocker\GA-AppLocker.psd1" -Force -ErrorAction Stop

# Now test if the functions exist
$functionsToTest = @(
    'Invoke-AddServiceAllowRules',
    'Invoke-AddAdminAllowRules',
    'Invoke-AddCommonDenyRules',
    'Invoke-AddDenyBrowserRules',
    'Invoke-RemoveDuplicateRules'
)

Write-Host "Testing if button handler functions exist..." -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

$allExist = $true
foreach ($funcName in $functionsToTest) {
    $exists = $null -ne (Get-Command -Name $funcName -ErrorAction SilentlyContinue)
    $status = if ($exists) { "✅ EXISTS" } else { "❌ MISSING" }
    Write-Host "$status - $funcName" -ForegroundColor $(if ($exists) { "Green" } else { "Red" })
    if (-not $exists) { $allExist = $false }
}

Write-Host ("=" * 60) -ForegroundColor Cyan

if ($allExist) {
    Write-Host "All button handler functions are available!" -ForegroundColor Green
    Write-Host "The buttons SHOULD work when clicked." -ForegroundColor Green
} else {
    Write-Host "Some button handler functions are missing!" -ForegroundColor Red
    Write-Host "This explains why the buttons don't work." -ForegroundColor Red
}
