# Phase 1: Critical Bug Fixes - Implementation Plan
**Date:** February 3, 2026
**Status:** In Progress
**Estimated Time:** 8.5-11.5 hours

## Overview

This phase addresses all 23 critical bugs identified in the ship readiness report. Each fix will be implemented and tested incrementally to ensure no regressions.

---

## Fix 1.1: Core Module - Pipeline Leaks (8 locations)

### Files to Fix:
- `GA-AppLocker/Modules/GA-AppLocker.Core/Functions/Event-System.ps1` (lines 119, 125, 185, 216)
- `GA-AppLocker/Modules/GA-AppLocker.Core/Functions/BackupRestore.ps1` (line 84)
- `GA-AppLocker/Modules/GA-AppLocker.Core/Functions/AuditTrail.ps1` (line 200)

### Fixes Required:

#### Event-System.ps1:185
```powershell
# BEFORE:
[void]$script:GA_AppLocker_EventHistory.Add($eventRecord)

# Check if already suppressed - this might already be correct
```

#### Event-System.ps1:119, 125, 216
```powershell
# BEFORE (line 119):
[void]$script:GA_AppLocker_EventHandlers[$EventName].Add($handlerEntry)

# BEFORE (line 125):
foreach ($h in $sorted) {
    [void]$script:GA_AppLocker_EventHandlers[$EventName].Add($h)
}

# BEFORE (line 216):
[void]$errors.Add($errorMsg)

# All appear to be correct with [void] prefix
# Need to verify actual code
```

#### BackupRestore.ps1:84
```powershell
# BEFORE:
$backupManifest.Contents += @{ ... }

# FIX:
[void]$backupManifest.Contents.Add(@{ ... })
# Or keep as is if += is intentional for array
```

#### AuditTrail.ps1:200
```powershell
# BEFORE:
try { [void]$parsed.Add(($line | ConvertFrom-Json)) } catch { }

# Already suppressed - verify
```

**Note:** Many of these may already be fixed. Need to verify actual code.

---

## Fix 1.2: Core Module - Audit Trail Performance (CRITICAL)

### File: `GA-AppLocker/Modules/GA-AppLocker.Core/Functions/AuditTrail.ps1`

### Issue: Line count check on EVERY write

### Fix:
```powershell
# Add module-level counter at top of file
$script:AuditWriteCounter = 0

# In Write-AuditLog function, after line 94:
$script:AuditWriteCounter++

# Replace the existing periodic check:
if ($script:AuditWriteCounter % 100 -eq 0) {
    # Only check line count every 100 writes
    $lineCount = 0
    try {
        $reader = [System.IO.File]::OpenText($auditPath)
        try {
            while ($null -ne $reader.ReadLine()) { $lineCount++ }
        }
        finally { $reader.Close() }
    }
    catch { $lineCount = 0 }

    if ($lineCount -gt 10000) {
        $backupPath = "$auditPath.bak"
        Copy-Item -Path $auditPath -Destination $backupPath -Force
        $linesToKeep = Get-Content -Path $auditPath -Tail 1000
        $linesToKeep | Set-Content -Path $auditPath -Force -Encoding UTF8
    }
}
```

---

## Fix 1.3: Core Module - Security - Log Injection

### File: `GA-AppLocker/Modules/GA-AppLocker.Core/Functions/AuditTrail.ps1`

### Issue: Line 203 - User data logged without sanitization

### Fix:
```powershell
# BEFORE (line 203):
catch { Write-AppLockerLog -Message "Failed to parse audit log line: $($_.Exception.Message)" -Level 'DEBUG' }

# FIX:
catch {
    $errorMsg = $_.Exception.Message -replace '[^\w\s\.\-:]', ''
    Write-AppLockerLog -Message "Failed to parse audit log line: $errorMsg" -Level 'DEBUG'
}
```

---

## Fix 1.4: Core Module - Security - HTML/CSV Injection

### File: `GA-AppLocker/Modules/GA-AppLocker.Core/Functions/ReportingExport.ps1`

### Issue: Lines 190, 267 - No output sanitization

### Fix for HTML (line 190):
```powershell
# BEFORE:
<td>$([System.Web.HttpUtility]::HtmlEncode($rule.Name))</td>

# Already uses HtmlEncode - verify CSV export
```

### Fix for CSV (line 267):
```powershell
# Need to check actual code
# Should wrap CSV values in quotes and escape embedded quotes
```

---

## Fix 1.5: Discovery Module - Connection Leaks

### File: `GA-AppLocker/Modules/GA-AppLocker.Discovery/Functions/LDAP-Functions.ps1`

### Issue: Lines 103-106, 114-117 - Connections not disposed on early return

### Fix (after line 106, after line 117):
```powershell
# BEFORE (line 106):
if ([string]::IsNullOrWhiteSpace($netCred.UserName)) {
    Write-AppLockerLog -Level Error -Message "LDAP connection failed: Credential has empty username."
    return $null
}

# FIX:
if ([string]::IsNullOrWhiteSpace($netCred.UserName)) {
    Write-AppLockerLog -Level Error -Message "LDAP connection failed: Credential has empty username."
    $connection.Dispose()
    return $null
}

# BEFORE (line 117):
if ($PasswordRequired -and $netCred.SecurePassword -eq $null) {
    Write-AppLockerLog -Level Error -Message "LDAP connection failed: Credential has no password."
    return $null
}

# FIX:
if ($PasswordRequired -and $netCred.SecurePassword -eq $null) {
    Write-AppLockerLog -Level Error -Message "LDAP connection failed: Credential has no password."
    $connection.Dispose()
    return $null
}
```

---

## Fix 1.6: Rules Module - Grouped Rules Never Saved

### File: `GA-AppLocker/Modules/GA-AppLocker.Rules/Functions/ConvertFrom-Artifact.ps1`

### Issue: Line 306-318 - Missing -Save parameter

### Fix:
```powershell
# Find the New-PublisherRule call around line 306
# BEFORE:
$pubResult = New-PublisherRule `
    -PublisherName $group.Publisher `
    ...
    # -Save:$Save  <-- MISSING

# FIX:
$pubResult = New-PublisherRule `
    -PublisherName $group.Publisher `
    -ProductName $product `
    -BinaryName $binary `
    -MinVersion $group.MinVersion `
    -MaxVersion $group.MaxVersion `
    -Action $group.Action `
    -UserOrGroupSid $group.UserOrGroupSid `
    -GroupName $group.GroupName `
    -GroupVendor $group.GroupVendor `
    -GroupCategory $group.GroupCategory `
    -CollectionType $collectionType `
    -Save:$Save  # ADD THIS
```

---

## Fix 1.7: Rules Module - Progress Exception Handling

### File: `GA-AppLocker/Modules/GA-AppLocker.Rules/Functions/Invoke-BatchRuleGeneration.ps1`

### Issue: Line 265 - Progress callback can throw

### Fix:
```powershell
# BEFORE (lines 262-268):
if ($OnProgress -and ($processed % 100 -eq 0)) {
    $pct = 45 + [int](35 * $processed / $total)
    if ($pct -gt $lastProgressPct) {
        & $OnProgress $pct "Creating: $processed / $total"
        $lastProgressPct = $pct
    }
}

# FIX:
if ($OnProgress -and ($processed % 100 -eq 0)) {
    $pct = 45 + [int](35 * $processed / $total)
    if ($pct -gt $lastProgressPct) {
        try {
            & $OnProgress $pct "Creating: $processed / $total"
            $lastProgressPct = $pct
        }
        catch {
            Write-AppLockerLog -Message "Progress callback failed: $($_.Exception.Message)" -Level 'WARNING'
        }
    }
}
```

---

## Fix 1.8: Rules Module - Null Referral Risk

### File: `GA-AppLocker/Modules/GA-AppLocker.Rules/Functions/Import-RulesFromXml.ps1`

### Issue: Lines 175-197 - Complex fallback can assign null

### Fix:
```powershell
# Find the sourceFileName logic around line 175-197
# BEFORE:
if ([string]::IsNullOrWhiteSpace($sourceFileName) -or $sourceFileName -eq 'Unknown') {
    $sourceFileName = $null
    $ruleName = $rule.Name  # Potential null ref
    if (-not [string]::IsNullOrWhiteSpace($ruleName) -and $ruleName -ne 'Unknown') {
        $cleaned = $ruleName -replace '[<>:"/\\|?*\x00-\x1F]', '_'
        $cleaned = [System.IO.Path]::GetFileNameWithoutExtension($cleaned)
        $sourceFileName = $cleaned
    }
}

# FIX:
if ([string]::IsNullOrWhiteSpace($sourceFileName) -or $sourceFileName -eq 'Unknown') {
    # Default to 'Hash Rule' if we can't resolve
    $sourceFileName = 'Hash Rule'
    $ruleName = $rule.Name
    if (-not [string]::IsNullOrWhiteSpace($ruleName) -and $ruleName -ne 'Unknown') {
        $cleaned = $ruleName -replace '[<>:"/\\|?*\x00-\x1F]', '_'
        $cleaned = [System.IO.Path]::GetFileNameWithoutExtension($cleaned)
        $sourceFileName = $cleaned
    }
}
# Later: $displayName = "$sourceFileName (Hash)"  # Now guaranteed not null
```

---

## Fix 1.9: Rules Module - Duplicate Detection Race Condition

### File: `GA-AppLocker/Modules/GA-AppLocker.Rules/Functions/New-HashRule.ps1`, `New-PublisherRule.ps1`

### Issue: Check-then-act pattern allows race condition

### Note: This is a hard problem to fix in PS 5.1 without proper locking. Will document as known limitation and implement best-effort fix.

### Mitigation:
```powershell
# In both files, add retry logic around save
if ($Save) {
    $existingRule = Find-ExistingHashRule -Hash $cleanHash -CollectionType $CollectionType
    if ($existingRule) {
        return $existingRule
    }

    # Create rule
    # ...

    # Save with retry
    $maxRetries = 3
    $retryCount = 0
    $saveSuccess = $false

    while (-not $saveSuccess -and $retryCount -lt $maxRetries) {
        try {
            Save-Rule -Rule $rule
            $saveSuccess = $true
        }
        catch {
            $retryCount++
            Start-Sleep -Milliseconds 100
            if ($retryCount -ge $maxRetries) {
                Write-AppLockerLog -Message "Failed to save rule after $maxRetries attempts" -Level 'ERROR'
                throw
            }
        }
    }
}
```

---

## Fix 1.10: Policy Module - O(n²) Array Operations (4 locations)

### Files:
- `GA-AppLocker/Modules/GA-AppLocker.Policy/Functions/Manage-PolicyRules.ps1` (lines 52, 129)
- `GA-AppLocker/Modules/GA-AppLocker.Policy/Functions/Export-PolicyToXml.ps1` (line 86)
- `GA-AppLocker/Modules/GA-AppLocker.Policy/Functions/Policy-Snapshots.ps1` (line 79)

### Fix 1: Manage-PolicyRules.ps1:52 (Add-RuleToPolicy)
```powershell
# BEFORE:
$currentRules = @($policy.RuleIds)
foreach ($id in $RuleId) {
    if ($id -notin $currentRules) {
        $currentRules += $id  # O(n) per iteration
        $addedCount++
    }
}

# FIX:
$currentRules = [System.Collections.Generic.List[string]]::new($policy.RuleIds)
foreach ($id in $RuleId) {
    if (-not $currentRules.Contains($id)) {
        [void]$currentRules.Add($id)
        $addedCount++
    }
}
$policy.RuleIds = @($currentRules)
```

### Fix 2: Manage-PolicyRules.ps1:129 (Remove-RuleFromPolicy)
```powershell
# BEFORE:
$currentRules = @($policy.RuleIds)
foreach ($id in $RuleId) {
    if ($id -in $currentRules) {
        $currentRules = $currentRules | Where-Object { $_ -ne $id }  # O(n) per iteration
        $removedCount++
    }
}

# FIX:
$currentRules = [System.Collections.Generic.List[string]]::new($policy.RuleIds)
foreach ($id in $RuleId) {
    if ($currentRules.Remove($id)) {  # Remove returns bool if found
        $removedCount++
    }
}
$policy.RuleIds = @($currentRules)
```

### Fix 3: Export-PolicyToXml.ps1:86
```powershell
# BEFORE:
$rules = @()
foreach ($ruleId in $policy.RuleIds) {
    $rule = Get-Content -Path $ruleFile -Raw | ConvertFrom-Json
    if ($rule.Status -eq 'Rejected' -and -not $IncludeRejected) {
        continue
    }
    $rules += $rule  # O(n) per iteration
}

# FIX:
$rules = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($ruleId in $policy.RuleIds) {
    $rule = Get-Content -Path $ruleFile -Raw | ConvertFrom-Json
    if ($rule.Status -eq 'Rejected' -and -not $IncludeRejected) {
        continue
    }
    [void]$rules.Add($rule)
}
$rulesArray = @($rules)
```

### Fix 4: Policy-Snapshots.ps1:79
```powershell
# BEFORE:
$rules = @()
if ($policy.RuleIds) {
    foreach ($ruleId in $policy.RuleIds) {
        $ruleResult = Get-Rule -Id $ruleId
        if ($ruleResult.Success) {
            $rules += $ruleResult.Data  # O(n) per iteration
        }
    }
}

# FIX:
$rules = [System.Collections.Generic.List[PSCustomObject]]::new()
if ($policy.RuleIds) {
    foreach ($ruleId in $policy.RuleIds) {
        $ruleResult = Get-Rule -Id $ruleId
        if ($ruleResult.Success) {
            [void]$rules.Add($ruleResult.Data)
        }
    }
}
$snapshot.Rules = @($rules)
```

---

## Fix 1.11: Deployment Module - Wrong Module Check

### File: `GA-AppLocker/Modules/GA-AppLocker.Deployment/Functions/GPO-Functions.ps1`

### Issue: Line 179 - Checks GroupPolicy instead of ActiveDirectory

### Fix:
```powershell
# BEFORE:
if (Get-Module -ListAvailable -Name GroupPolicy) {
    New-GPLink -Name $job.GPOName -Target $ouDN -ErrorAction Stop
}

# FIX:
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    New-GPLink -Name $job.GPOName -Target $ouDN -ErrorAction Stop
}
```

---

## Fix 1.12: Deployment Module - Policy Status Silent Failure

### File: `GA-AppLocker/Modules/GA-AppLocker.Deployment/Functions/Start-Deployment.ps1`

### Issue: Line 208 - Result discarded

### Fix:
```powershell
# BEFORE:
Set-PolicyStatus -PolicyId $job.PolicyId -Status 'Deployed' | Out-Null

# FIX:
$statusResult = Set-PolicyStatus -PolicyId $job.PolicyId -Status 'Deployed'
if (-not $statusResult.Success) {
    Write-AppLockerLog -Level Warning -Message "Failed to set policy status: $($statusResult.Error)"
}
```

---

## Fix 1.13: Storage Module - O(n²) Array Concatenation (2 locations)

### Files:
- `GA-AppLocker/Modules/GA-AppLocker.Storage/Functions/BulkOperations.ps1` (line 218)
- `GA-AppLocker/Modules/GA-AppLocker.Storage/Functions/RuleStorage.ps1` (line 451)

### Fix 1: BulkOperations.ps1:218 (Add-RulesToIndex)
```powershell
# BEFORE:
$script:JsonIndex.Rules = @($script:JsonIndex.Rules) + $newEntries.ToArray()

# FIX:
# Convert to List if needed
if ($script:JsonIndex.Rules -isnot [System.Collections.Generic.List[PSCustomObject]]) {
    $rulesList = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($r in @($script:JsonIndex.Rules)) {
        [void]$rulesList.Add($r)
    }
    $script:JsonIndex.Rules = $rulesList
}
# O(1) amortized append
[void]$script:JsonIndex.Rules.AddRange($newEntries)
```

### Fix 2: RuleStorage.ps1:451 (Get-AllRules filtering)
```powershell
# BEFORE: Multiple O(n) array copies
$filtered = @($rules)
if ($Status) {
    $filtered = @($filtered | Where-Object { $_.Status -eq $Status })
}
if ($RuleType) {
    $filtered = @($filtered | Where-Object { $_.RuleType -eq $RuleType })
}
# ... more filters

# FIX: Single-pass O(n) filtering
$filtered = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($rule in $rules) {
    $match = $true
    if ($Status -and $rule.Status -ne $Status) { $match = $false }
    if ($RuleType -and $rule.RuleType -ne $RuleType) { $match = $false }
    if ($CollectionType -and $rule.CollectionType -ne $CollectionType) { $match = $false }
    if ($GroupVendor -and $rule.GroupVendor -notlike "*$GroupVendor*") { $match = $false }
    if ($SearchText) {
        $textMatch = $rule.Name -like "*$SearchText*" -or
                     $rule.PublisherName -like "*$SearchText*" -or
                     $rule.Path -like "*$SearchText*" -or
                     $rule.Hash -like "*$SearchText*"
        if (-not $textMatch) { $match = $false }
    }
    if ($match) { [void]$filtered.Add($rule) }
}

$result.Total = $filtered.Count
```

---

## Fix 1.14: Storage Module - Index Sync Failure

### File: `GA-AppLocker/Modules/GA-AppLocker.Storage/Functions/RuleStorage.ps1`

### Issue: Lines 590-645 - Update-Rule doesn't update HashIndex/PublisherIndex

### Fix (add after line 634):
```powershell
# Add HashIndex update if hash changed
if ($UpdatedRule.Hash -and $UpdatedRule.Hash -ne $indexEntry.Hash) {
    $oldHash = $indexEntry.Hash.ToUpper()
    if ($oldHash -and $script:HashIndex.ContainsKey($oldHash)) {
        $script:HashIndex.Remove($oldHash)
    }
    $newHash = $UpdatedRule.Hash.ToUpper()
    $script:HashIndex[$newHash] = $ruleId
    $indexEntry.Hash = $UpdatedRule.Hash
}

# Add PublisherIndex update if publisher/product changed
$oldPubKey = if ($indexEntry.PublisherName) {
    "$($indexEntry.PublisherName)|$($indexEntry.ProductName)".ToLower()
} else { $null }
$newPubKey = if ($UpdatedRule.PublisherName) {
    "$($UpdatedRule.PublisherName)|$($UpdatedRule.ProductName)".ToLower()
} else { $null }

if ($oldPubKey -ne $newPubKey) {
    if ($oldPubKey -and $script:PublisherIndex.ContainsKey($oldPubKey)) {
        $script:PublisherIndex.Remove($oldPubKey)
    }
    if ($newPubKey) {
        $script:PublisherIndex[$newPubKey] = $ruleId
    }

    # Update PublisherOnlyIndex
    $oldPubOnlyKey = if ($indexEntry.PublisherName) { $indexEntry.PublisherName.ToLower() } else { $null }
    $newPubOnlyKey = if ($UpdatedRule.PublisherName) { $UpdatedRule.PublisherName.ToLower() } else { $null }

    if ($oldPubOnlyKey -ne $newPubOnlyKey) {
        if ($oldPubOnlyKey -and $script:PublisherOnlyIndex.ContainsKey($oldPubOnlyKey)) {
            $script:PublisherOnlyIndex.Remove($oldPubOnlyKey)
        }
        if ($newPubOnlyKey) {
            $script:PublisherOnlyIndex[$newPubOnlyKey] = $ruleId
        }
    }

    $indexEntry.PublisherName = $UpdatedRule.PublisherName
    $indexEntry.ProductName = $UpdatedRule.ProductName
}
```

---

## Fix 1.15: Validation Module - False Negative

### File: `GA-AppLocker/Modules/GA-AppLocker.Validation/Functions/Test-AppLockerPolicyImport.ps1`

### Issue: Line 46 - Uses hardcoded "Everyone" SID

### Fix:
```powershell
# BEFORE (line 46):
$testResult = $xmlContent | Test-AppLockerPolicy -Path "C:\Windows\System32\cmd.exe" -User "Everyone" -ErrorAction Stop

# FIX:
# Extract all unique SIDs from policy
$sids = @()
$ruleCollections = $policy.AppLockerPolicy.RuleCollection
if ($ruleCollections) {
    foreach ($collection in $ruleCollections) {
        foreach ($ruleType in @('FilePublisherRule', 'FileHashRule', 'FilePathRule')) {
            if ($collection.$ruleType) {
                if ($collection.$ruleType -is [array]) {
                    $sids += $collection.$ruleType | ForEach-Object { $_.UserOrGroupSid }
                } else {
                    $sids += $collection.$ruleType.UserOrGroupSid
                }
            }
        }
    }
}

$sids = $sids | Sort-Object -Unique

# Validate each unique SID
foreach ($sid in $sids) {
    if ([string]::IsNullOrWhiteSpace($sid)) {
        $result.Error = "Policy contains rule with empty UserOrGroupSid"
        return $result
    }

    $testPath = if (Test-Path "C:\Windows\System32\cmd.exe") {
        "C:\Windows\System32\cmd.exe"
    } else {
        "$env:SystemRoot\System32\cmd.exe"
    }

    $testResult = $xmlContent | Test-AppLockerPolicy -Path $testPath -User $sid -ErrorAction Stop
    if (-not $testResult) {
        $result.Error = "Policy invalid for SID: $sid"
        return $result
    }
}

$result.Success = $true
$result.CanImport = $true
$result.ParsedPolicy = "Policy validated for all SIDs ($($sids.Count) unique)"
```

---

## Fix 1.16: Version Mismatch

### File: `CLAUDE.md`

### Issue: Line 2 shows version 1.2.56, should be 1.2.60

### Fix:
```markdown
# BEFORE:
**Version:** 1.2.56 | **Tests:** not run (not requested) | **Exported Commands:** ~195

# FIX:
**Version:** 1.2.60 | **Tests:** not run (not requested) | **Exported Commands:** ~195
```

---

## Testing Strategy

After each fix set:
1. Run existing behavioral tests (when Pester fixed)
2. Manual test the specific functionality
3. Verify no regressions

### E2E Test Cases:
- Launch dashboard
- Create and save a hash rule
- Create and save a publisher rule
- Create a policy
- Add rules to policy
- Export policy to XML
- Import policy from XML
- Validate policy XML

---

## Implementation Order

1. Fix 1.1: Pipeline leaks (Core)
2. Fix 1.2: Audit trail performance
3. Fix 1.3-1.4: Security fixes
4. Fix 1.5: Connection leaks
5. Fix 1.6-1.9: Rules module fixes
6. Fix 1.10: Policy module fixes
7. Fix 1.11-1.12: Deployment module fixes
8. Fix 1.13-1.14: Storage module fixes
9. Fix 1.15: Validation module fix
10. Fix 1.16: Version update

---

## Status Tracking

- [ ] Fix 1.1: Core pipeline leaks
- [ ] Fix 1.2: Audit trail performance
- [ ] Fix 1.3: Log injection security
- [ ] Fix 1.4: HTML/CSV injection security
- [ ] Fix 1.5: Discovery connection leaks
- [ ] Fix 1.6: Rules grouped save bug
- [ ] Fix 1.7: Rules progress exception
- [ ] Fix 1.8: Rules null referral
- [ ] Fix 1.9: Rules race condition
- [ ] Fix 1.10: Policy O(n²) operations
- [ ] Fix 1.11: Deployment module check
- [ ] Fix 1.12: Deployment status failure
- [ ] Fix 1.13: Storage O(n²) operations
- [ ] Fix 1.14: Storage index sync
- [ ] Fix 1.15: Validation false negative
- [ ] Fix 1.16: Version mismatch

---

## Next Steps

After Phase 1 complete:
1. Run full test suite
2. Verify all critical bugs resolved
3. Update SHIP_READINESS_REPORT.md
4. Begin Phase 2: High Priority Fixes
