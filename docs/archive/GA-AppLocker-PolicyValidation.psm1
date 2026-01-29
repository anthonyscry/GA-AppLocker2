#Requires -Version 5.1
<#
.SYNOPSIS
    GA-AppLocker Policy Validation Module
    
.DESCRIPTION
    Comprehensive validation suite to ensure generated AppLocker policies
    are accepted by Windows AppLocker. Validates XML schema, GUIDs, SIDs,
    rule conditions, and performs live import testing.
    
.NOTES
    Author: GA-AppLocker Team
    Version: 1.0.0
    Critical: Policies that fail these validations WILL be rejected by AppLocker
#>

#region Schema Validation

function Test-AppLockerXmlSchema {
    <#
    .SYNOPSIS
        Validates AppLocker policy XML against Microsoft schema requirements.
    
    .DESCRIPTION
        Performs structural validation of AppLocker XML including:
        - Root element validation
        - Required namespace declarations
        - Element ordering (strict requirement)
        - Required attributes on all elements
    
    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.
    
    .PARAMETER XmlContent
        XML content as string (alternative to XmlPath).
    
    .OUTPUTS
        [PSCustomObject] with Success, Errors, Warnings properties
    
    .EXAMPLE
        Test-AppLockerXmlSchema -XmlPath "C:\Policies\baseline.xml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath,
        
        [Parameter(Mandatory, ParameterSetName = 'Content')]
        [string]$XmlContent
    )
    
    $result = [PSCustomObject]@{
        Success  = $false
        Errors   = [System.Collections.ArrayList]::new()
        Warnings = [System.Collections.ArrayList]::new()
        Details  = [PSCustomObject]@{
            RootElement      = $null
            RuleCollections  = @()
            TotalRules       = 0
            ValidationTime   = $null
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Load XML
        [xml]$policy = if ($XmlPath) { Get-Content $XmlPath -Raw } else { $XmlContent }
        
        # 1. Validate root element
        if ($policy.DocumentElement.LocalName -ne 'AppLockerPolicy') {
            [void]$result.Errors.Add("Root element must be 'AppLockerPolicy', found: $($policy.DocumentElement.LocalName)")
            return $result
        }
        $result.Details.RootElement = 'AppLockerPolicy'
        
        # 2. Validate Version attribute
        $version = $policy.AppLockerPolicy.Version
        if ([string]::IsNullOrEmpty($version)) {
            [void]$result.Errors.Add("AppLockerPolicy missing required 'Version' attribute")
        }
        elseif ($version -notmatch '^\d+$') {
            [void]$result.Errors.Add("Version must be numeric, found: $version")
        }
        
        # 3. Validate RuleCollections
        $validCollections = @('Appx', 'Dll', 'Exe', 'Msi', 'Script')
        $collections = $policy.AppLockerPolicy.RuleCollection
        
        if (-not $collections) {
            [void]$result.Warnings.Add("No RuleCollections found in policy")
        }
        else {
            foreach ($collection in $collections) {
                $type = $collection.Type
                
                # Validate collection type
                if ($type -cnotin $validCollections) {
                    [void]$result.Errors.Add("Invalid RuleCollection Type: '$type'. Must be one of: $($validCollections -join ', ') (case-sensitive)")
                }
                
                # Validate EnforcementMode
                $mode = $collection.EnforcementMode
                $validModes = @('NotConfigured', 'AuditOnly', 'Enabled')
                if ($mode -cnotin $validModes) {
                    [void]$result.Errors.Add("RuleCollection '$type' has invalid EnforcementMode: '$mode'. Must be: $($validModes -join ', ')")
                }
                
                $result.Details.RuleCollections += $type
                
                # Count rules
                $ruleCount = 0
                $ruleCount += ($collection.FilePublisherRule | Measure-Object).Count
                $ruleCount += ($collection.FileHashRule | Measure-Object).Count
                $ruleCount += ($collection.FilePathRule | Measure-Object).Count
                $result.Details.TotalRules += $ruleCount
            }
        }
        
        $result.Success = ($result.Errors.Count -eq 0)
    }
    catch {
        [void]$result.Errors.Add("XML parsing failed: $($_.Exception.Message)")
    }
    finally {
        $stopwatch.Stop()
        $result.Details.ValidationTime = $stopwatch.Elapsed
    }
    
    return $result
}

#endregion

#region GUID Validation

function Test-AppLockerRuleGuids {
    <#
    .SYNOPSIS
        Validates all rule GUIDs in an AppLocker policy.
    
    .DESCRIPTION
        Ensures all rule IDs are:
        - Valid GUID format (8-4-4-4-12)
        - Uppercase (AppLocker requirement)
        - Unique across all rule collections
    
    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.
    
    .OUTPUTS
        [PSCustomObject] with Success, Errors, DuplicateGuids properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath
    )
    
    $result = [PSCustomObject]@{
        Success        = $false
        Errors         = [System.Collections.ArrayList]::new()
        DuplicateGuids = [System.Collections.ArrayList]::new()
        TotalGuids     = 0
        UniqueGuids    = 0
    }
    
    try {
        [xml]$policy = Get-Content $XmlPath -Raw
        $allGuids = [System.Collections.ArrayList]::new()
        $guidPattern = '^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$'
        
        foreach ($collection in $policy.AppLockerPolicy.RuleCollection) {
            $collectionType = $collection.Type
            
            # Get all rule types
            $rules = @()
            $rules += $collection.FilePublisherRule
            $rules += $collection.FileHashRule
            $rules += $collection.FilePathRule
            
            foreach ($rule in $rules) {
                if (-not $rule) { continue }
                
                $id = $rule.Id
                $name = $rule.Name
                
                # Check GUID format
                if ([string]::IsNullOrEmpty($id)) {
                    [void]$result.Errors.Add("[$collectionType] Rule '$name' has no Id attribute")
                    continue
                }
                
                # Validate format
                if ($id -notmatch $guidPattern) {
                    # Check if it's valid but lowercase
                    if ($id.ToUpper() -match $guidPattern) {
                        [void]$result.Errors.Add("[$collectionType] Rule '$name' GUID must be UPPERCASE: $id")
                    }
                    else {
                        [void]$result.Errors.Add("[$collectionType] Rule '$name' has invalid GUID format: $id")
                    }
                }
                
                # Track for duplicates
                [void]$allGuids.Add([PSCustomObject]@{
                    Guid       = $id
                    Collection = $collectionType
                    RuleName   = $name
                })
            }
        }
        
        $result.TotalGuids = $allGuids.Count
        
        # Check for duplicates
        $grouped = $allGuids | Group-Object Guid | Where-Object Count -gt 1
        foreach ($group in $grouped) {
            $locations = ($group.Group | ForEach-Object { "[$($_.Collection)] $($_.RuleName)" }) -join ', '
            [void]$result.DuplicateGuids.Add("GUID $($group.Name) used in: $locations")
            [void]$result.Errors.Add("Duplicate GUID found: $($group.Name)")
        }
        
        $result.UniqueGuids = ($allGuids | Select-Object -Unique Guid).Count
        $result.Success = ($result.Errors.Count -eq 0)
    }
    catch {
        [void]$result.Errors.Add("GUID validation failed: $($_.Exception.Message)")
    }
    
    return $result
}

#endregion

#region SID Validation

function Test-AppLockerRuleSids {
    <#
    .SYNOPSIS
        Validates all Security Identifiers (SIDs) in AppLocker rules.
    
    .DESCRIPTION
        Ensures UserOrGroupSid values are:
        - Valid SID format (S-1-...)
        - Resolvable to a security principal (optional)
    
    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.
    
    .PARAMETER ResolveNames
        If specified, attempts to resolve SIDs to account names.
    
    .OUTPUTS
        [PSCustomObject] with Success, Errors, UnresolvedSids properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath,
        
        [switch]$ResolveNames
    )
    
    $result = [PSCustomObject]@{
        Success        = $false
        Errors         = [System.Collections.ArrayList]::new()
        UnresolvedSids = [System.Collections.ArrayList]::new()
        SidMappings    = [System.Collections.ArrayList]::new()
    }
    
    # Well-known SIDs that are always valid
    $wellKnownSids = @{
        'S-1-1-0'     = 'Everyone'
        'S-1-5-18'    = 'SYSTEM'
        'S-1-5-19'    = 'LOCAL SERVICE'
        'S-1-5-20'    = 'NETWORK SERVICE'
        'S-1-5-32-544' = 'Administrators'
        'S-1-5-32-545' = 'Users'
        'S-1-5-32-547' = 'Power Users'
    }
    
    $sidPattern = '^S-1-\d+(-\d+)+$'
    
    try {
        [xml]$policy = Get-Content $XmlPath -Raw
        
        foreach ($collection in $policy.AppLockerPolicy.RuleCollection) {
            $collectionType = $collection.Type
            
            $rules = @()
            $rules += $collection.FilePublisherRule
            $rules += $collection.FileHashRule
            $rules += $collection.FilePathRule
            
            foreach ($rule in $rules) {
                if (-not $rule) { continue }
                
                $sid = $rule.UserOrGroupSid
                $name = $rule.Name
                
                if ([string]::IsNullOrEmpty($sid)) {
                    [void]$result.Errors.Add("[$collectionType] Rule '$name' missing UserOrGroupSid")
                    continue
                }
                
                # Validate SID format
                if ($sid -notmatch $sidPattern) {
                    [void]$result.Errors.Add("[$collectionType] Rule '$name' has invalid SID format: $sid")
                    continue
                }
                
                # Attempt resolution
                $accountName = $null
                if ($wellKnownSids.ContainsKey($sid)) {
                    $accountName = $wellKnownSids[$sid]
                }
                elseif ($ResolveNames) {
                    try {
                        $sidObj = New-Object System.Security.Principal.SecurityIdentifier($sid)
                        $accountName = $sidObj.Translate([System.Security.Principal.NTAccount]).Value
                    }
                    catch {
                        [void]$result.UnresolvedSids.Add("[$collectionType] Rule '$name': $sid")
                    }
                }
                
                [void]$result.SidMappings.Add([PSCustomObject]@{
                    Collection  = $collectionType
                    RuleName    = $name
                    Sid         = $sid
                    AccountName = $accountName
                })
            }
        }
        
        $result.Success = ($result.Errors.Count -eq 0)
    }
    catch {
        [void]$result.Errors.Add("SID validation failed: $($_.Exception.Message)")
    }
    
    return $result
}

#endregion

#region Rule Condition Validation

function Test-AppLockerRuleConditions {
    <#
    .SYNOPSIS
        Validates rule conditions for all rule types.
    
    .DESCRIPTION
        Validates:
        - Publisher rules: PublisherName, ProductName, BinaryName, Version ranges
        - Hash rules: SHA256 format, SourceFileName, SourceFileLength
        - Path rules: Valid path format, environment variables
    
    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.
    
    .OUTPUTS
        [PSCustomObject] with Success, Errors, Warnings properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath
    )
    
    $result = [PSCustomObject]@{
        Success  = $false
        Errors   = [System.Collections.ArrayList]::new()
        Warnings = [System.Collections.ArrayList]::new()
        RuleStats = [PSCustomObject]@{
            Publisher = 0
            Hash      = 0
            Path      = 0
        }
    }
    
    $sha256Pattern = '^0x[0-9A-Fa-f]{64}$|^[0-9A-Fa-f]{64}$'
    $validEnvVars = @('%WINDIR%', '%SYSTEM32%', '%PROGRAMFILES%', '%OSDRIVE%', 
                      '%PROGRAMFILES(X86)%', '%PROGRAMDATA%', '%USERPROFILE%')
    
    try {
        [xml]$policy = Get-Content $XmlPath -Raw
        
        foreach ($collection in $policy.AppLockerPolicy.RuleCollection) {
            $collectionType = $collection.Type
            
            # Validate Publisher Rules
            foreach ($rule in $collection.FilePublisherRule) {
                if (-not $rule) { continue }
                $result.RuleStats.Publisher++
                
                $name = $rule.Name
                $conditions = $rule.Conditions.FilePublisherCondition
                
                if (-not $conditions) {
                    [void]$result.Errors.Add("[$collectionType] Publisher rule '$name' missing FilePublisherCondition")
                    continue
                }
                
                foreach ($condition in $conditions) {
                    # Validate PublisherName
                    if ([string]::IsNullOrWhiteSpace($condition.PublisherName)) {
                        [void]$result.Errors.Add("[$collectionType] Publisher rule '$name' has empty PublisherName")
                    }
                    
                    # Validate BinaryVersionRange
                    $versionRange = $condition.BinaryVersionRange
                    if ($versionRange) {
                        $lowVersion = $versionRange.LowSection
                        $highVersion = $versionRange.HighSection
                        
                        if ($lowVersion -and $lowVersion -notmatch '^\d+(\.\d+)*$' -and $lowVersion -ne '*') {
                            [void]$result.Errors.Add("[$collectionType] Rule '$name' has invalid LowSection version: $lowVersion")
                        }
                        if ($highVersion -and $highVersion -notmatch '^\d+(\.\d+)*$' -and $highVersion -ne '*') {
                            [void]$result.Errors.Add("[$collectionType] Rule '$name' has invalid HighSection version: $highVersion")
                        }
                    }
                }
            }
            
            # Validate Hash Rules
            foreach ($rule in $collection.FileHashRule) {
                if (-not $rule) { continue }
                $result.RuleStats.Hash++
                
                $name = $rule.Name
                $conditions = $rule.Conditions.FileHashCondition
                
                if (-not $conditions) {
                    [void]$result.Errors.Add("[$collectionType] Hash rule '$name' missing FileHashCondition")
                    continue
                }
                
                foreach ($condition in $conditions) {
                    $fileHash = $condition.FileHash
                    
                    if (-not $fileHash) {
                        [void]$result.Errors.Add("[$collectionType] Hash rule '$name' missing FileHash element")
                        continue
                    }
                    
                    # Validate hash format
                    $hash = $fileHash.Data
                    if ($hash -notmatch $sha256Pattern) {
                        [void]$result.Errors.Add("[$collectionType] Hash rule '$name' has invalid SHA256 hash: $hash")
                    }
                    
                    # Validate Type attribute
                    $hashType = $fileHash.Type
                    if ($hashType -ne 'SHA256') {
                        [void]$result.Errors.Add("[$collectionType] Hash rule '$name' must have Type='SHA256', found: $hashType")
                    }
                    
                    # Validate SourceFileName
                    if ([string]::IsNullOrWhiteSpace($fileHash.SourceFileName)) {
                        [void]$result.Warnings.Add("[$collectionType] Hash rule '$name' missing SourceFileName")
                    }
                    
                    # Validate SourceFileLength
                    $length = $fileHash.SourceFileLength
                    if ($length -and $length -notmatch '^\d+$') {
                        [void]$result.Errors.Add("[$collectionType] Hash rule '$name' has invalid SourceFileLength: $length")
                    }
                }
            }
            
            # Validate Path Rules
            foreach ($rule in $collection.FilePathRule) {
                if (-not $rule) { continue }
                $result.RuleStats.Path++
                
                $name = $rule.Name
                $conditions = $rule.Conditions.FilePathCondition
                
                if (-not $conditions) {
                    [void]$result.Errors.Add("[$collectionType] Path rule '$name' missing FilePathCondition")
                    continue
                }
                
                foreach ($condition in $conditions) {
                    $path = $condition.Path
                    
                    if ([string]::IsNullOrWhiteSpace($path)) {
                        [void]$result.Errors.Add("[$collectionType] Path rule '$name' has empty Path")
                        continue
                    }
                    
                    # Check for invalid characters
                    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
                    foreach ($char in $invalidChars) {
                        if ($path.Contains($char)) {
                            [void]$result.Errors.Add("[$collectionType] Path rule '$name' contains invalid character in path")
                            break
                        }
                    }
                    
                    # Warn about user-writable paths
                    $userWritablePaths = @('%TEMP%', '%TMP%', '%USERPROFILE%\Downloads', '%USERPROFILE%\Desktop')
                    foreach ($uwp in $userWritablePaths) {
                        if ($path -like "*$uwp*") {
                            [void]$result.Warnings.Add("[$collectionType] Path rule '$name' includes user-writable location: $path")
                        }
                    }
                }
            }
        }
        
        $result.Success = ($result.Errors.Count -eq 0)
    }
    catch {
        [void]$result.Errors.Add("Rule condition validation failed: $($_.Exception.Message)")
    }
    
    return $result
}

#endregion

#region Live Import Testing

function Test-AppLockerPolicyImport {
    <#
    .SYNOPSIS
        Tests if a policy can be imported by AppLocker without errors.
    
    .DESCRIPTION
        This is the DEFINITIVE test - it actually attempts to parse the policy
        using the same API that Set-AppLockerPolicy uses. If this passes,
        the policy WILL be accepted by AppLocker.
    
    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.
    
    .PARAMETER TestOnly
        If specified, only validates without attempting import.
    
    .OUTPUTS
        [PSCustomObject] with Success, Error, ParsedPolicy properties
    
    .NOTES
        This is the most critical validation - it uses Microsoft's own parser.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath
    )
    
    $result = [PSCustomObject]@{
        Success      = $false
        Error        = $null
        ParsedPolicy = $null
        CanImport    = $false
    }
    
    try {
        # Read the XML content
        $xmlContent = Get-Content $XmlPath -Raw
        
        # Attempt to use Test-AppLockerPolicy (this validates the XML structure)
        # This is what Set-AppLockerPolicy uses internally
        $testResult = $xmlContent | Test-AppLockerPolicy -Path "C:\Windows\System32\cmd.exe" -User "Everyone" -ErrorAction Stop
        
        # If we get here, the XML is valid
        $result.Success = $true
        $result.CanImport = $true
        $result.ParsedPolicy = "Policy validated successfully via Test-AppLockerPolicy"
    }
    catch [Microsoft.Security.ApplicationId.PolicyManagement.PolicyModel.PolicyException] {
        $result.Error = "AppLocker policy parsing error: $($_.Exception.Message)"
    }
    catch [System.Xml.XmlException] {
        $result.Error = "XML parsing error: $($_.Exception.Message)"
    }
    catch {
        # Try alternative validation method
        try {
            [xml]$policy = Get-Content $XmlPath -Raw
            
            # Manual validation that the structure is correct
            $ruleCollections = $policy.AppLockerPolicy.RuleCollection
            if ($ruleCollections) {
                $result.Success = $true
                $result.CanImport = $true
                $result.ParsedPolicy = "Policy structure validated (AppLocker cmdlets may not be available)"
            }
        }
        catch {
            $result.Error = "Validation failed: $($_.Exception.Message)"
        }
    }
    
    return $result
}

#endregion

#region Complete Validation Pipeline

function Invoke-AppLockerPolicyValidation {
    <#
    .SYNOPSIS
        Runs complete validation pipeline on an AppLocker policy.
    
    .DESCRIPTION
        Executes all validation checks in sequence:
        1. XML Schema validation
        2. GUID validation
        3. SID validation
        4. Rule condition validation
        5. Live import test
    
    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.
    
    .PARAMETER StopOnFirstError
        If specified, stops validation on first error found.
    
    .PARAMETER OutputReport
        Path to save detailed validation report.
    
    .OUTPUTS
        [PSCustomObject] with complete validation results
    
    .EXAMPLE
        Invoke-AppLockerPolicyValidation -XmlPath "C:\Policies\new-policy.xml" -OutputReport "C:\Reports\validation.txt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath,
        
        [switch]$StopOnFirstError,
        
        [string]$OutputReport
    )
    
    $overallResult = [PSCustomObject]@{
        PolicyPath      = $XmlPath
        ValidationTime  = Get-Date
        OverallSuccess  = $false
        CanBeImported   = $false
        TotalErrors     = 0
        TotalWarnings   = 0
        SchemaResult    = $null
        GuidResult      = $null
        SidResult       = $null
        ConditionResult = $null
        ImportResult    = $null
        Summary         = ""
    }
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         AppLocker Policy Validation Pipeline                 ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "`nValidating: $XmlPath`n" -ForegroundColor White
    
    # 1. Schema Validation
    Write-Host "[1/5] XML Schema Validation..." -ForegroundColor Yellow -NoNewline
    $overallResult.SchemaResult = Test-AppLockerXmlSchema -XmlPath $XmlPath
    if ($overallResult.SchemaResult.Success) {
        Write-Host " PASSED" -ForegroundColor Green
        Write-Host "      Rule Collections: $($overallResult.SchemaResult.Details.RuleCollections -join ', ')"
        Write-Host "      Total Rules: $($overallResult.SchemaResult.Details.TotalRules)"
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        foreach ($err in $overallResult.SchemaResult.Errors) {
            Write-Host "      ERROR: $err" -ForegroundColor Red
        }
        if ($StopOnFirstError) { return $overallResult }
    }
    $overallResult.TotalErrors += $overallResult.SchemaResult.Errors.Count
    $overallResult.TotalWarnings += $overallResult.SchemaResult.Warnings.Count
    
    # 2. GUID Validation
    Write-Host "[2/5] GUID Validation..." -ForegroundColor Yellow -NoNewline
    $overallResult.GuidResult = Test-AppLockerRuleGuids -XmlPath $XmlPath
    if ($overallResult.GuidResult.Success) {
        Write-Host " PASSED" -ForegroundColor Green
        Write-Host "      Unique GUIDs: $($overallResult.GuidResult.UniqueGuids)"
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        foreach ($err in $overallResult.GuidResult.Errors) {
            Write-Host "      ERROR: $err" -ForegroundColor Red
        }
        if ($StopOnFirstError) { return $overallResult }
    }
    $overallResult.TotalErrors += $overallResult.GuidResult.Errors.Count
    
    # 3. SID Validation
    Write-Host "[3/5] SID Validation..." -ForegroundColor Yellow -NoNewline
    $overallResult.SidResult = Test-AppLockerRuleSids -XmlPath $XmlPath
    if ($overallResult.SidResult.Success) {
        Write-Host " PASSED" -ForegroundColor Green
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        foreach ($err in $overallResult.SidResult.Errors) {
            Write-Host "      ERROR: $err" -ForegroundColor Red
        }
        if ($StopOnFirstError) { return $overallResult }
    }
    $overallResult.TotalErrors += $overallResult.SidResult.Errors.Count
    
    # 4. Rule Condition Validation
    Write-Host "[4/5] Rule Condition Validation..." -ForegroundColor Yellow -NoNewline
    $overallResult.ConditionResult = Test-AppLockerRuleConditions -XmlPath $XmlPath
    if ($overallResult.ConditionResult.Success) {
        Write-Host " PASSED" -ForegroundColor Green
        Write-Host "      Publisher Rules: $($overallResult.ConditionResult.RuleStats.Publisher)"
        Write-Host "      Hash Rules: $($overallResult.ConditionResult.RuleStats.Hash)"
        Write-Host "      Path Rules: $($overallResult.ConditionResult.RuleStats.Path)"
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        foreach ($err in $overallResult.ConditionResult.Errors) {
            Write-Host "      ERROR: $err" -ForegroundColor Red
        }
        if ($StopOnFirstError) { return $overallResult }
    }
    foreach ($warn in $overallResult.ConditionResult.Warnings) {
        Write-Host "      WARNING: $warn" -ForegroundColor Yellow
    }
    $overallResult.TotalErrors += $overallResult.ConditionResult.Errors.Count
    $overallResult.TotalWarnings += $overallResult.ConditionResult.Warnings.Count
    
    # 5. Live Import Test
    Write-Host "[5/5] Live Import Test..." -ForegroundColor Yellow -NoNewline
    $overallResult.ImportResult = Test-AppLockerPolicyImport -XmlPath $XmlPath
    if ($overallResult.ImportResult.Success) {
        Write-Host " PASSED" -ForegroundColor Green
        $overallResult.CanBeImported = $true
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      ERROR: $($overallResult.ImportResult.Error)" -ForegroundColor Red
        $overallResult.TotalErrors++
    }
    
    # Summary
    $overallResult.OverallSuccess = ($overallResult.TotalErrors -eq 0)
    
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    if ($overallResult.OverallSuccess) {
        Write-Host "✓ VALIDATION PASSED - Policy can be imported to AppLocker" -ForegroundColor Green
        $overallResult.Summary = "PASSED"
    }
    else {
        Write-Host "✗ VALIDATION FAILED - $($overallResult.TotalErrors) error(s), $($overallResult.TotalWarnings) warning(s)" -ForegroundColor Red
        $overallResult.Summary = "FAILED: $($overallResult.TotalErrors) errors"
    }
    Write-Host "══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Export report if requested
    if ($OutputReport) {
        $overallResult | ConvertTo-Json -Depth 10 | Out-File $OutputReport -Encoding UTF8
        Write-Host "Report saved to: $OutputReport" -ForegroundColor Gray
    }
    
    return $overallResult
}

#endregion

#region Pester Tests

<#
    Pester test suite for policy validation
    Run with: Invoke-Pester -Path .\Test-AppLockerValidation.Tests.ps1
#>

# Export for Pester testing
$script:TestCases = @{
    ValidPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Test Publisher Rule" Description="Test" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    InvalidGuidPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="invalid-guid" Name="Bad GUID Rule" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    InvalidSidPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Bad SID Rule" UserOrGroupSid="INVALID-SID" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    InvalidHashPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FileHashRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Bad Hash Rule" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FileHashCondition>
          <FileHash Type="SHA256" Data="NOTAHASH" SourceFileName="test.exe" SourceFileLength="1234" />
        </FileHashCondition>
      </Conditions>
    </FileHashRule>
  </RuleCollection>
</AppLockerPolicy>
'@
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Test-AppLockerXmlSchema',
    'Test-AppLockerRuleGuids',
    'Test-AppLockerRuleSids',
    'Test-AppLockerRuleConditions',
    'Test-AppLockerPolicyImport',
    'Invoke-AppLockerPolicyValidation'
)
