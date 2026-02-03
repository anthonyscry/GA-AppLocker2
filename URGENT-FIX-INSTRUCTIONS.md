# URGENT: Fix Module Caching Issue

## The Problem

You're running v1.2.60 but PowerShell is serving **cached old code** from v1.2.55 or earlier.

**Evidence:**
- Your logs show v1.2.60 starting
- But you're getting errors that were fixed in v1.2.60
- Diagnostic tests confirm the code on disk is correct

## The Solution

### Option 1: Use the Force-Fresh Script (RECOMMENDED)

```powershell
# Close GA-AppLocker if running
# Then run:
.\Run-Dashboard-ForceFresh.ps1
```

This script:
1. Clears PowerShell's module analysis cache
2. Removes all GA-AppLocker modules from memory
3. Verifies the version matches before starting
4. Launches the dashboard with fresh code

### Option 2: Manual Cache Clear

If Option 1 doesn't work:

```powershell
# 1. Close GA-AppLocker completely

# 2. Delete the module cache
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\ModuleAnalysisCache" -Force -ErrorAction SilentlyContinue

# 3. Remove from memory
Remove-Module GA-AppLocker* -Force -ErrorAction SilentlyContinue

# 4. Close PowerShell completely and reopen

# 5. Run the dashboard
.\Run-Dashboard.ps1
```

### Option 3: Nuclear Option

If both above fail:

```powershell
# 1. Close ALL PowerShell windows

# 2. Delete these folders:
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\ModuleAnalysisCache" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\*" -Include "*.psm1", "*.psd1" -Force -ErrorAction SilentlyContinue

# 3. Restart your computer (yes, really)

# 4. Open fresh PowerShell as Administrator

# 5. Navigate to GA-AppLocker folder

# 6. Run:
.\Run-Dashboard.ps1
```

## How to Verify It Worked

After clearing the cache, the app should:

1. ✅ **Scanning finds EXE/DLL/MSI files** (not just Appx)
2. ✅ **Rule buttons work** (Service Allow, Admin Allow, Deny Paths)
3. ✅ **No "term not recognized" errors** in the log
4. ✅ **AD Discovery auto-refreshes** after connectivity test

## Why This Happened

PowerShell caches module metadata for performance. When you:
1. Have the app running
2. Update the module files
3. Restart the app

PowerShell serves the **cached old version** instead of reading the new files from disk.

This is a known PowerShell limitation, not a bug in GA-AppLocker.

## If Problems Persist

If you still see issues after clearing the cache:

1. Check the log file for the FIRST error
2. Send me the FULL log from startup to first error
3. Run this diagnostic:

```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force
(Get-Module GA-AppLocker).Version
Get-Command Save-RulesBulk | Select-Object Name, ModuleName, Version
```

Send me the output.

---

**I apologize for the confusion. The code is correct, but PowerShell's caching made it appear broken.**
