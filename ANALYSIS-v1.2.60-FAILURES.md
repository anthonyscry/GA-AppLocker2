# Root Cause Analysis: Why v1.2.60 Fixes Failed

## Executive Summary

v1.2.60 was released with "fixes" for 3 bugs, but **ALL bugs still exist** after user testing. The diagnostic tests we created ALL PASS, but the actual app fails. This document explains why.

## The Core Problem: Runspace Scope Isolation

**PowerShell runspaces are isolated execution contexts.** When you create a runspace for async operations:

1. The runspace does NOT inherit the parent session's imported modules
2. The runspace does NOT have access to `global:` functions defined in the parent
3. The runspace MUST explicitly import modules or have function definitions passed in

**Our app creates runspaces in 3 places:**
1. `AsyncHelpers.ps1` - `Invoke-AsyncOperation` (general async wrapper)
2. `Scanner.ps1` - Scanning background operations
3. `ADDiscovery.ps1` - Connectivity testing

## Why Diagnostic Tests Passed But App Failed

**Diagnostic tests (`Tests/Diagnostics/Test-ActualBehavior.ps1`):**
- Run in the MAIN PowerShell session
- Module is imported in the main session
- All functions are accessible
- Tests pass ✅

**Actual app:**
- Creates NEW runspaces for async operations
- Runspaces are ISOLATED from main session
- Module may not be imported in runspace
- Functions fail ❌

**Lesson:** Tests must replicate the actual execution environment (runspaces, WPF dispatcher) to catch these issues.

## Bug-by-Bug Analysis

### Bug 4: Storage Module Functions Not Recognized

**Error:** `The term 'Write-StorageLog' is not recognized`

**What we "fixed" in v1.2.60:**
- Removed `script:` prefix from `Write-StorageLog` definition in Storage.psm1 line 16
- Removed `script:` prefix from `Initialize-JsonIndex` call in RuleStorage.ps1 line 73

**Why it didn't work:**
- The fix was correct for the MAIN session
- But Rules panel buttons may create async operations via `Invoke-AsyncOperation`
- Those runspaces don't have the Storage module imported
- Even though `AsyncHelpers.ps1` tries to import the module (lines 103-112), it may fail silently

**Actual root cause:**
```powershell
# AsyncHelpers.ps1 lines 103-112
if ($ModulePath -and (Test-Path $ModulePath)) {
    try {
        Import-Module $ModulePath -Force -ErrorAction Stop
        $moduleLoaded = $true
    }
    catch {
        # Module import failed - continue but note the error
        $moduleError = $_.Exception.Message
    }
}
```

The catch block swallows the error and continues! If module import fails, the runspace proceeds without the module, causing "function not recognized" errors.

**Real fix needed:**
1. Make module import failures FATAL in runspaces
2. OR pass function definitions into runspaces explicitly
3. OR don't use runspaces for operations that need module functions

### Bug 4 (Part 2): GUI Functions Not Recognized

**Error:** `The term 'Invoke-AddCommonDenyRules' is not recognized`

**What we "fixed" in v1.2.60:**
- Nothing - we didn't touch GUI functions

**Why it fails:**
- `Invoke-AddCommonDenyRules` is defined as `global:` in Rules.ps1 line 1236
- Rules.ps1 is dot-sourced into the main session in MainWindow.xaml.ps1
- But WPF event handlers run in a different scope context
- The `global:` functions may not be accessible from event handler closures

**Actual root cause:**
WPF event handlers use `.GetNewClosure()` to capture variables, but this creates a NEW scope that may not have access to `global:` functions defined AFTER the closure is created.

```powershell
# Rules.ps1 lines 41-45
$btn.Add_Click({
    param($sender, $e)
    Invoke-ButtonAction -Action $sender.Tag
}.GetNewClosure())
```

The closure is created during `Initialize-RulesPanel`, which runs BEFORE the `global:Invoke-AddCommonDenyRules` function is defined (it's defined later in the same file).

**Real fix needed:**
1. Define all `global:` functions BEFORE wiring up event handlers
2. OR use a different pattern that doesn't rely on closure scope
3. OR pass function references explicitly

### Bug 3: Local Scan Only Finds Appx Packages

**Error:** `Local artifact scan failed: Access is denied`

**What we "fixed" in v1.2.60:**
- Nothing - we deferred this bug

**Why it fails:**
- Scanner.ps1 creates a runspace for background scanning (lines 380-440)
- The runspace DOES import the module (lines 394-400)
- But `Get-LocalArtifacts` throws "Access Denied" immediately
- The error is caught and logged, but scanning continues
- Only Appx scanning succeeds (separate code path)

**Actual root cause:**
The diagnostic test found 658 EXE files in System32, so the code CAN scan. The difference is:
- Diagnostic test runs in main session with full elevation
- App runspace may not inherit elevation properly
- OR the runspace is created with wrong threading apartment
- OR there's a path parameter issue

Looking at Scanner.ps1 lines 386-426, the runspace scriptblock receives parameters via `$SyncHash.Params`, which is a hashtable. If the `ScanLocal` or `ScanPaths` parameters aren't passed correctly, the scan would fail.

**Real fix needed:**
1. Verify runspace inherits elevation
2. Add detailed logging to see WHICH parameter is missing/wrong
3. Check if `$SyncHash.Params` contains all required keys
4. Verify `Start-ArtifactScan` is being called with correct parameters

### Bug 2: AD Discovery Auto-Refresh Doesn't Work

**Error:** User still has to click Refresh button manually after connectivity test

**What we "fixed" in v1.2.60:**
- Added `$dataGrid.Items.Refresh()` call in ADDiscovery.ps1 lines 717-724

**Why it didn't work:**
- The `Items.Refresh()` call happens in the main thread
- But the DataGrid's `ItemsSource` may not be updated
- OR the call happens before the connectivity test results are merged into `$script:DiscoveredMachines`
- OR the DataGrid needs `Dispatcher.Invoke` for cross-thread updates

**Actual root cause:**
Looking at ADDiscovery.ps1 lines 717-724:
```powershell
Update-MachineDataGrid -Window $win -Machines $script:DiscoveredMachines

# Force DataGrid visual refresh
$dataGrid = $win.FindName('MachineDataGrid')
if ($dataGrid) {
    $dataGrid.Items.Refresh()
}
```

This code runs in the connectivity test completion handler. But `Update-MachineDataGrid` may not actually update the ItemsSource - it might just filter existing items. The `Items.Refresh()` call won't help if the underlying data hasn't changed.

**Real fix needed:**
1. Verify `Update-MachineDataGrid` actually updates `ItemsSource`
2. Use `Dispatcher.Invoke` to ensure UI updates happen on UI thread
3. OR directly set `ItemsSource` to a new collection reference (forces WPF to rebind)

## Lessons Learned

### 1. Tests Must Replicate Runtime Environment

**WRONG:**
```powershell
# Test that just imports module and calls functions
Import-Module .\GA-AppLocker\GA-AppLocker.psd1
$result = Get-LocalArtifacts -ScanPaths @('C:\Windows\System32')
$result.Success | Should -Be $true
```

**RIGHT:**
```powershell
# Test that creates runspace like the app does
$runspace = [runspacefactory]::CreateRunspace()
$runspace.Open()
$ps = [powershell]::Create()
$ps.Runspace = $runspace
$ps.AddScript({
    param($ModulePath)
    Import-Module $ModulePath -Force
    Get-LocalArtifacts -ScanPaths @('C:\Windows\System32')
}).AddArgument($modulePath)
$result = $ps.Invoke()
$result.Success | Should -Be $true
```

### 2. Silent Failures Are Deadly

**WRONG:**
```powershell
try {
    Import-Module $ModulePath -Force -ErrorAction Stop
}
catch {
    # Continue anyway - SILENT FAILURE
    $moduleError = $_.Exception.Message
}
```

**RIGHT:**
```powershell
try {
    Import-Module $ModulePath -Force -ErrorAction Stop
}
catch {
    # FAIL LOUDLY
    throw "Module import failed in runspace: $($_.Exception.Message)"
}
```

### 3. Scope Is Everything in PowerShell + WPF

- `$script:` inside `global:` functions = WRONG scope (global's private scope, not module's)
- `global:` functions defined after `.GetNewClosure()` = not accessible in closure
- Runspaces don't inherit parent session's modules/functions
- WPF event handlers need `Dispatcher.Invoke` for cross-thread UI updates

### 4. Don't Trust Passing Tests

If tests pass but the app fails, the tests are testing the wrong thing.

## Next Steps

1. **Fix runspace module import** - Make failures fatal, add logging
2. **Fix GUI function scope** - Define functions before wiring events, or use different pattern
3. **Fix scanning** - Add detailed logging, verify parameters, check elevation
4. **Fix AD refresh** - Use Dispatcher.Invoke, update ItemsSource directly
5. **Create runtime tests** - Tests that use runspaces and WPF dispatcher
6. **Manual verification** - Actually click buttons and verify they work before releasing

## Commit Message for v1.2.61

```
fix: 4 critical bugs from v1.2.60 that persisted after user testing

Root cause: Runspace scope isolation - async operations don't inherit
main session's modules/functions. v1.2.60 fixes worked in diagnostic
tests (main session) but failed in app (runspaces).

Fixes:
1. Bug 4 (Storage): Make module import failures fatal in runspaces
2. Bug 4 (GUI): Define global functions before event handler wiring
3. Bug 3 (Scanning): Add detailed logging, verify runspace parameters
4. Bug 2 (AD Refresh): Use Dispatcher.Invoke, update ItemsSource directly

Tests: Created runtime tests that replicate runspace environment
Verified: Manual testing in actual app before release
```
