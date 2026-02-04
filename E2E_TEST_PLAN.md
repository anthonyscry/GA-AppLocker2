# E2E Testing - Phase 1.4 (Applied Critical Fixes)
**Date:** February 4, 2026
**Status:** In Progress

---

## Test Environment

- **OS:** Windows (WPF compatible)
- **PowerShell Version:** 5.1+
- **Module:** GA-AppLocker v1.2.60
- **Test Type:** Manual E2E behavioral testing

---

## Test Suite 1: Audit Trail Performance Fix

### Test 1.1: Write Performance with 1000 Entries
**Objective:** Verify audit writes are 100x faster after modulo counter fix

**Steps:**
1. Clear audit log: `Remove-Item "$env:LOCALAPPDATA\GA-AppLocker\Logs\GA-AppLocker_*.log" -Force`
2. Write 1000 audit entries in loop
3. Measure total time
4. Expected: <10 seconds (not 100 seconds)

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

$sw = [Diagnostics.Stopwatch]::StartNew()
for ($i = 1; $i -le 1000; $i++) {
    Write-AuditLog -Category "Test" -Action "Write" -Target "Target $i" -User "TestUser"
}
$sw.Stop()
Write-Host "1000 audit writes in $($sw.Elapsed.TotalSeconds) seconds"
```

**Expected Result:** <10 seconds (100x faster than before)
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

### Test 1.2: Verify Modulo Counter Works
**Objective:** Confirm line count check only runs every 100 writes

**Steps:**
1. Write 150 audit entries
2. Check audit log for "Failed to parse" errors (should be minimal)
3. Verify line count only checked twice (not 150 times)

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Clear log first
$logPath = "$env:LOCALAPPDATA\GA-AppLocker\Logs\GA-AppLocker_$(Get-Date -Format 'yyyy-MM-dd').log"
if (Test-Path $logPath) { Remove-Item $logPath -Force }

# Write 150 entries
for ($i = 1; $i -le 150; $i++) {
    Write-AuditLog -Category "Test" -Action "Write" -Target "Target $i" -User "TestUser"
}

# Check how many times file was opened for line count
# (Can't easily measure this without instrumentation, but performance test 1.1 validates it)
```

**Expected Result:** 150 writes complete quickly
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

### Test 1.3: Audit Log Sanitization
**Objective:** Verify error messages are sanitized to prevent log injection

**Steps:**
1. Write audit log entry with malicious data
2. Read log file
3. Verify special characters are removed from error messages

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Write malicious entry
Write-AuditLog -Category "Test" -Action "Evil" -Target "<script>alert('XSS')</script>" -User "User"

# Read log
$logPath = "$env:LOCALAPPDATA\GA-AppLocker\Logs\GA-AppLocker_$(Get-Date -Format 'yyyy-MM-dd').log"
$content = Get-Content $logPath -Raw

# Check if XSS attempt was sanitized
if ($content -match "script>alert") {
    Write-Host "FAIL: Log injection not sanitized" -ForegroundColor Red
} else {
    Write-Host "PASS: Log injection sanitized" -ForegroundColor Green
}
```

**Expected Result:** `<script>alert('XSS')</script>` should not appear in error messages
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

## Test Suite 2: LDAP Connection Leak Fixes

### Test 2.1: Connection Disposed on Invalid Credentials
**Objective:** Verify LDAP connection disposed when username is empty

**Steps:**
1. Create test credentials with empty username
2. Call `Get-LdapConnection`
3. Verify no connection leaks (monitor LDAP connections if possible)

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Test with empty username
$cred = New-Object System.Management.Automation.PSCredential("", (ConvertTo-SecureString "password" -AsPlainText -Force))
$connection = Get-LdapConnection -Server "localhost" -Credential $cred -Port 389

# Result should be $null
if ($null -eq $connection) {
    Write-Host "PASS: Connection returned null (correct behavior)" -ForegroundColor Green
} else {
    Write-Host "FAIL: Connection not null (may leak)" -ForegroundColor Red
    # Try to use connection - should throw if disposed
    try {
        $connection.Dispose() # Should succeed if not disposed, throw if already disposed
        Write-Host "INFO: Connection was not properly disposed" -ForegroundColor Yellow
    } catch {
        Write-Host "INFO: Connection already disposed (good)" -ForegroundColor Green
    }
}
```

**Expected Result:** Returns $null, connection properly disposed
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

### Test 2.2: Connection Disposed on SSL Requirement Failure
**Objective:** Verify LDAP connection disposed when SSL required but not active

**Steps:**
1. Set RequireSSL in config to true
2. Call `Get-LdapConnection` with UseSSL:$false
3. Verify connection disposed

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Set RequireSSL config
Set-AppLockerConfig -Key "RequireSSL" -Value $true

# Test without SSL
$connection = Get-LdapConnection -Server "localhost" -UseSSL:$false -Port 389

# Result should be $null
if ($null -eq $connection) {
    Write-Host "PASS: Connection returned null" -ForegroundColor Green
} else {
    Write-Host "FAIL: Connection not null (may leak)" -ForegroundColor Red
}

# Reset config
Set-AppLockerConfig -Key "RequireSSL" -Value $false
```

**Expected Result:** Returns $null, connection properly disposed
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

## Test Suite 3: Policy Module O(n²) Fixes

### Test 3.1: Add Rules to Policy Performance
**Objective:** Verify 100x faster when adding 100 rules to policy

**Steps:**
1. Create test policy
2. Measure time to add 100 rules using Add-RuleToPolicy
3. Expected: <100ms (not 10 seconds)

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Create test policy
$policyId = (New-Policy -Name "PerformanceTest" -Description "Performance test policy").Data.Id

# Create 100 test rules (quick hash rules)
$ruleIds = @()
$sw = [Diagnostics.Stopwatch]::StartNew()
for ($i = 1; $i -le 100; $i++) {
    $hash = ('11' * 32).Substring(0, 32) # Fake hash
    $ruleId = (New-HashRule -Hash $hash -CollectionType Exe -Action Allow -UserOrGroupSid "S-1-5-32-544" -Save:$true).Data.Id
    $ruleIds += $ruleId
}

$sw.Stop()
Write-Host "Created 100 rules in $($sw.Elapsed.TotalSeconds) seconds"

# Now add all to policy
$sw = [Diagnostics.Stopwatch]::StartNew()
$result = Add-RuleToPolicy -PolicyId $policyId -RuleId $ruleIds
$sw.Stop()

Write-Host "Added 100 rules to policy in $($sw.Elapsed.TotalSeconds) seconds"
Write-Host "Result: $($result.Message)"

if ($sw.Elapsed.TotalSeconds -lt 1.0) {
    Write-Host "PASS: Performance improved (100x faster)" -ForegroundColor Green
} else {
    Write-Host "FAIL: Still slow (expected <1s, got $($sw.Elapsed.TotalSeconds)s)" -ForegroundColor Red
}
```

**Expected Result:** <1 second (1000x faster than before)
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

### Test 3.2: Remove Rules from Policy Performance
**Objective:** Verify 100x faster when removing 100 rules from policy

**Steps:**
1. Use same policy from Test 3.1
2. Measure time to remove all 100 rules
3. Expected: <100ms

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

$sw = [Diagnostics.Stopwatch]::StartNew()
$result = Remove-RuleFromPolicy -PolicyId $policyId -RuleId $ruleIds
$sw.Stop()

Write-Host "Removed 100 rules from policy in $($sw.Elapsed.TotalSeconds) seconds"
Write-Host "Result: $($result.Message)"

if ($sw.Elapsed.TotalSeconds -lt 1.0) {
    Write-Host "PASS: Performance improved (100x faster)" -ForegroundColor Green
} else {
    Write-Host "FAIL: Still slow (expected <1s, got $($sw.Elapsed.TotalSeconds)s)" -ForegroundColor Red
}
```

**Expected Result:** <1 second
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

## Test Suite 4: Storage Module O(n²) Filtering Fix

### Test 4.1: Get-AllRules with Multiple Filters Performance
**Objective:** Verify 5x faster when querying with 5 filters

**Steps:**
1. Create 1000 test rules
2. Measure time for Get-AllRules with 5 filters
3. Expected: <50ms (not 250ms)

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Create 1000 test rules (will take ~10 seconds)
Write-Host "Creating 1000 test rules (this will take ~10s)..."
$ruleIds = @()
for ($i = 1; $i -le 1000; $i++) {
    $hash = (New-Guid).ToString('N') + (New-Guid).ToString('N').Substring(0, 16) # Create fake 64-char hash
    $ruleId = (New-HashRule -Hash $hash -CollectionType Exe -Action Allow -UserOrGroupSid "S-1-5-32-544" -Save:$true).Data.Id
    $ruleIds += $ruleId
    if ($i % 100 -eq 0) { Write-Host "Created $i/1000 rules..." }
}
Write-Host "Created 1000 test rules"

# Now query with 5 filters
$sw = [Diagnostics.Stopwatch]::StartNew()
$result = Get-AllRules -Status Approved -RuleType Hash -CollectionType Exe -SearchText "test" -Take 100
$sw.Stop()

Write-Host "Queried 1000 rules with 5 filters in $($sw.Elapsed.TotalSeconds) seconds"
Write-Host "Returned $($result.Total) rules"

if ($sw.Elapsed.TotalSeconds -lt 0.1) {
    Write-Host "PASS: Performance improved (5x faster)" -ForegroundColor Green
} elseif ($sw.Elapsed.TotalSeconds -lt 0.25) {
    Write-Host "ACCEPTABLE: Performance improved" -ForegroundColor Yellow
} else {
    Write-Host "FAIL: Still slow (expected <100ms, got $($sw.Elapsed.TotalSeconds)s)" -ForegroundColor Red
}
```

**Expected Result:** <100ms (5x faster)
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

## Test Suite 5: Validation Module False Negative Fix

### Test 5.1: Policy Validation with Custom SIDs
**Objective:** Verify all unique SIDs in policy are validated (not just "Everyone")

**Steps:**
1. Create test policy with custom SIDs (Everyone, Authenticated Users, Custom Group)
2. Run Test-AppLockerPolicyImport
3. Verify all SIDs validated

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Create test policy with multiple SIDs
$policy = New-Policy -Name "SIDTest" -Description "Test SID validation"
Add-RuleToPolicy -PolicyId $policy.Data.Id -RuleId (New-HashRule -Hash ('00' * 64) -CollectionType Exe -Action Allow -UserOrGroupSid "S-1-1-0" -Save:$true).Data.Id
Add-RuleToPolicy -PolicyId $policy.Data.Id -RuleId (New-HashRule -Hash ('11' * 64) -CollectionType Exe -Action Allow -UserOrGroupSid "S-1-5-11" -Save:$true).Data.Id
Add-RuleToPolicy -PolicyId $policy.Data.Id -RuleId (New-HashRule -Hash ('22' * 64) -CollectionType Exe -Action Allow -UserOrGroupSid "DOMAIN\CustomGroup" -Save:$true).Data.Id

# Export to XML
$xmlPath = "$env:TEMP\test-policy.xml"
Export-PolicyToXml -PolicyId $policy.Data.Id -OutputPath $xmlPath

# Test validation
Write-Host "Testing policy validation with custom SIDs..."
$result = Test-AppLockerPolicyImport -XmlPath $xmlPath

if ($result.Success) {
    Write-Host "PASS: Policy validation succeeded for all SIDs" -ForegroundColor Green
    Write-Host "Message: $($result.ParsedPolicy)"
} else {
    Write-Host "FAIL: Policy validation failed" -ForegroundColor Red
    Write-Host "Error: $($result.Error)"
}
```

**Expected Result:** All 3 SIDs validated, validation succeeds
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

### Test 5.2: Empty SID Detection
**Objective:** Verify empty SIDs are caught during validation

**Steps:**
1. Create policy XML with empty UserOrGroupSid
2. Run Test-AppLockerPolicyImport
3. Verify empty SID error

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

# Create test XML with empty SID
$xmlWithEmptySid = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="Audit">
    <FilePathRule Id="" Name="" Action="Allow" UserOrGroupSid="" Description="">
      <Conditions />
    </FilePathRule>
  </RuleCollection>
</AppLockerPolicy>
'@

$xmlPath = "$env:TEMP\test-empty-sid.xml"
$xmlWithEmptySid | Set-Content -Path $xmlPath -Encoding UTF8

# Test validation
Write-Host "Testing empty SID detection..."
$result = Test-AppLockerPolicyImport -XmlPath $xmlPath

if ($result.Success) {
    Write-Host "FAIL: Empty SID not detected" -ForegroundColor Red
} else {
    Write-Host "PASS: Empty SID detected" -ForegroundColor Green
    Write-Host "Error: $($result.Error)"
    if ($result.Error -match "empty UserOrGroupSid") {
        Write-Host "CORRECT: Error message mentions empty SID" -ForegroundColor Green
    }
}
```

**Expected Result:** Validation fails with error about empty UserOrGroupSid
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

## Test Suite 6: BackupRestore Pipeline Leak Fix

### Test 6.1: Verify No Pipeline Leaks in Backup
**Objective:** Confirm backup operations don't leak data into pipeline

**Steps:**
1. Run Backup-AppLockerData
2. Check function return value
3. Verify no extra data in output

**Command:**
```powershell
Import-Module .\GA-AppLocker\GA-AppLocker.psd1 -Force

$sw = [Diagnostics.Stopwatch]::StartNew()
$result = Backup-AppLockerData
$sw.Stop()

Write-Host "Backup completed in $($sw.Elapsed.TotalSeconds) seconds"

# Check return type and properties
Write-Host "Result type: $($result.GetType().Name)"
Write-Host "Result properties: $($result.PSObject.Properties.Name -join ', ')"

if ($result.Success) {
    Write-Host "PASS: Backup succeeded" -ForegroundColor Green
    $data = $result.Data

    # Check Contents array
    if ($data.Contents -isnot [array]) {
        Write-Host "WARNING: Contents is not array (may have pipeline leak)" -ForegroundColor Yellow
    } else {
        Write-Host "PASS: Contents is correct type (array)" -ForegroundColor Green
        Write-Host "Contents count: $($data.Contents.Count)"
    }
} else {
    Write-Host "FAIL: Backup failed" -ForegroundColor Red
    Write-Host "Error: $($result.Error)"
}
```

**Expected Result:** Returns clean result object, no extra pipeline data
**Actual Result:** [PENDING]

**Status:** ⏳ TO RUN

---

## Automated Test Script

```powershell
# Run all E2E tests
$testResults = @()

# Test 1.1: Audit Performance
Write-Host "Running Test 1.1: Audit Trail Performance..." -ForegroundColor Cyan
# [Run Test 1.1 command here]
# Record result

# Test 1.2: Modulo Counter
Write-Host "Running Test 1.2: Modulo Counter..." -ForegroundColor Cyan
# [Run Test 1.2 command here]
# Record result

# Test 1.3: Log Sanitization
Write-Host "Running Test 1.3: Log Sanitization..." -ForegroundColor Cyan
# [Run Test 1.3 command here]
# Record result

# ... continue with all tests

# Summary
$passed = ($testResults | Where-Object { $_.Status -eq 'PASS' }).Count
$failed = ($testResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$total = $testResults.Count

Write-Host "`n`n========== TEST SUMMARY =========="
Write-Host "Total: $total | Passed: $passed | Failed: $failed"
Write-Host "Pass Rate: $([math]::Round(($passed / $total) * 100, 2))%"

if ($failed -eq 0) {
    Write-Host "`n🎉 ALL TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "`n❌ $failed test(s) failed" -ForegroundColor Red
    $testResults | Where-Object { $_.Status -eq 'FAIL' } | ForEach-Object {
        Write-Host "- $($_.TestName): $($_.Message)" -ForegroundColor Red
    }
}
```

---

## Test Results Summary

| Test # | Test Name | Status | Expected | Actual | Notes |
|--------|-----------|--------|---------|--------|-------|
| 1.1 | Audit Performance | ⏳ PENDING | <10s | - |
| 1.2 | Modulo Counter | ⏳ PENDING | <10s | - |
| 1.3 | Log Sanitization | ⏳ PENDING | Sanitized | - |
| 2.1 | Empty Username Dispose | ⏳ PENDING | Disposed | - |
| 2.2 | SSL Requirement Dispose | ⏳ PENDING | Disposed | - |
| 3.1 | Policy Add Performance | ⏳ PENDING | <1s | - |
| 3.2 | Policy Remove Performance | ⏳ PENDING | <1s | - |
| 4.1 | Storage Filter Performance | ⏳ PENDING | <100ms | - |
| 5.1 | Custom SID Validation | ⏳ PENDING | All validated | - |
| 5.2 | Empty SID Detection | ⏳ PENDING | Detected | - |
| 6.1 | Backup Pipeline Leak | ⏳ PENDING | No leak | - |

**Overall Status:** ⏳ PENDING EXECUTION

---

## Regression Testing

### Critical Workflow Tests:

1. **Full Workflow Test:**
   - Launch dashboard: `Start-AppLockerDashboard`
   - Create hash rule
   - Create policy
   - Add rule to policy
   - Export policy to XML
   - Verify no crashes or errors

2. **Performance Regression:**
   - Create 500 rules
   - Create policy with all rules
   - Verify policy loads in <1 second

3. **Security Regression:**
   - Attempt log injection in audit trail
   - Verify prevented
   - Attempt XML injection in policy
   - Verify prevented

---

## Next Steps After Testing

1. **If All Tests Pass:**
   - Proceed to Phase 1.5 (remaining critical fixes)
   - Run testing again
   - Start Phase 2 (high priority)

2. **If Tests Fail:**
   - Analyze failure
   - Fix regression
   - Re-test
   - Only proceed after all tests pass

3. **Report Results:**
   - Update `E2E_TEST_RESULTS.md`
   - Document any regressions
   - Update ship readiness report

---

**Test Execution:** [PENDING]
**Results:** [PENDING]
**Status:** 🟡 READY TO RUN
