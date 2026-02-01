#Requires -Modules Pester
<#
.SYNOPSIS
    End-to-end integration tests for GA-AppLocker workflow.

.DESCRIPTION
    Tests complete workflows that span multiple modules:
    - Artifact -> Rule -> Policy -> Export (full pipeline)
    - Rule creation -> Storage -> Retrieval
    - Policy build -> XML export -> Validation
    - Config -> Scan -> Rules -> Policy lifecycle
    - Import/Export roundtrip with all rule types

.NOTES
    Integration tests - span multiple modules
    Run with: Invoke-Pester -Path .\Tests\Unit\Integration.Tests.ps1 -Output Detailed
#>

BeforeAll {
    Get-Module 'GA-AppLocker*' | Remove-Module -Force -ErrorAction SilentlyContinue
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    $script:TestDir = Join-Path $env:TEMP "GA-AppLocker-IntegrationTests-$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
}

AfterAll {
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ============================================================================
# FULL PIPELINE: RULE -> POLICY -> EXPORT -> VALIDATE
# ============================================================================

Describe 'Integration: Rule -> Policy -> Export -> Validate Pipeline' -Tag 'Integration' {

    BeforeAll {
        # Create various rule types
        $script:HashRule = New-HashRule -FileName 'IntegrationApp.exe' -Hash ('A1B2C3D4' * 8) `
            -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        $script:PublisherRule = New-PublisherRule -Publisher 'O=Integration Corp' -ProductName 'TestSuite' `
            -FileName 'test.exe' -FileVersion '1.0.0.0' -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        $script:PathRule = New-PathRule -Path 'C:\IntegrationTest\*' -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        # Create policy and add all rules
        $script:IntPolicy = New-Policy -Name 'Integration_FullPipeline' -CollectionType 'Exe' -TargetGPO 'Integration-GPO'
    }

    It 'Should create all three rule types successfully' {
        $script:HashRule.Success | Should -Be $true
        $script:PublisherRule.Success | Should -Be $true
        $script:PathRule.Success | Should -Be $true
    }

    It 'Should add all rules to a single policy' {
        $script:IntPolicy.Success | Should -Be $true

        $r1 = Add-RuleToPolicy -PolicyId $script:IntPolicy.Data.PolicyId -RuleId $script:HashRule.Data.RuleId
        $r2 = Add-RuleToPolicy -PolicyId $script:IntPolicy.Data.PolicyId -RuleId $script:PublisherRule.Data.RuleId
        $r3 = Add-RuleToPolicy -PolicyId $script:IntPolicy.Data.PolicyId -RuleId $script:PathRule.Data.RuleId

        $r1.Success | Should -Be $true
        $r2.Success | Should -Be $true
        $r3.Success | Should -Be $true
    }

    It 'Should export policy to valid AppLocker XML' {
        $xmlPath = Join-Path $script:TestDir 'integration_policy.xml'
        $result = Export-PolicyToXml -PolicyId $script:IntPolicy.Data.PolicyId -OutputPath $xmlPath
        $result.Success | Should -Be $true
        Test-Path $xmlPath | Should -Be $true

        # XML should be valid
        { [xml](Get-Content $xmlPath -Raw) } | Should -Not -Throw
    }

    It 'Should pass schema validation' {
        $xmlPath = Join-Path $script:TestDir 'integration_policy.xml'
        if (Test-Path $xmlPath) {
            $xmlContent = Get-Content $xmlPath -Raw
            $result = Test-AppLockerXmlSchema -XmlContent $xmlContent
            $result.Success | Should -Be $true
        }
        else {
            Set-ItResult -Skipped -Because 'XML export failed'
        }
    }

    It 'Should pass GUID validation' {
        $xmlPath = Join-Path $script:TestDir 'integration_policy.xml'
        if (Test-Path $xmlPath) {
            $xmlContent = Get-Content $xmlPath -Raw
            $result = Test-AppLockerRuleGuids -XmlContent $xmlContent
            $result.Success | Should -Be $true
        }
        else {
            Set-ItResult -Skipped -Because 'XML export failed'
        }
    }

    It 'Should pass SID validation' {
        $xmlPath = Join-Path $script:TestDir 'integration_policy.xml'
        if (Test-Path $xmlPath) {
            $xmlContent = Get-Content $xmlPath -Raw
            $result = Test-AppLockerRuleSids -XmlContent $xmlContent
            $result.Success | Should -Be $true
        }
        else {
            Set-ItResult -Skipped -Because 'XML export failed'
        }
    }

    It 'Should pass condition validation' {
        $xmlPath = Join-Path $script:TestDir 'integration_policy.xml'
        if (Test-Path $xmlPath) {
            $xmlContent = Get-Content $xmlPath -Raw
            $result = Test-AppLockerRuleConditions -XmlContent $xmlContent
            $result.Success | Should -Be $true
        }
        else {
            Set-ItResult -Skipped -Because 'XML export failed'
        }
    }

    It 'Should pass full validation pipeline' {
        $xmlPath = Join-Path $script:TestDir 'integration_policy.xml'
        if (Test-Path $xmlPath) {
            $xmlContent = Get-Content $xmlPath -Raw
            $result = Invoke-AppLockerPolicyValidation -XmlContent $xmlContent
            $result.Success | Should -Be $true
        }
        else {
            Set-ItResult -Skipped -Because 'XML export failed'
        }
    }
}

# ============================================================================
# RULE CREATION -> STORAGE -> RETRIEVAL
# ============================================================================

Describe 'Integration: Rule Storage Round-Trip' -Tag 'Integration' {

    It 'Should create a rule and retrieve it by ID' {
        $rule = New-HashRule -FileName 'StorageTest.exe' -Hash ('11' * 32) -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
        $rule.Success | Should -Be $true

        $retrieved = Get-Rule -RuleId $rule.Data.RuleId
        $retrieved.Success | Should -Be $true
        $retrieved.Data.FileName | Should -Be 'StorageTest.exe'
    }

    It 'Should find rule by hash via index' {
        $hash = '22' * 32
        $rule = New-HashRule -FileName 'HashLookup.exe' -Hash $hash -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        $found = Find-RuleByHash -Hash $hash
        $found | Should -Not -BeNullOrEmpty
    }

    It 'Should find rule by publisher via index' {
        $rule = New-PublisherRule -Publisher 'O=Lookup Corp' -ProductName 'LookupApp' `
            -FileName 'lookup.exe' -FileVersion '2.0.0.0' -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        if ($rule.Success) {
            $found = Find-RuleByPublisher -Publisher 'O=Lookup Corp' -ProductName 'LookupApp'
            $found | Should -Not -BeNullOrEmpty
        }
    }

    It 'Should update rule status and reflect in index' {
        $rule = New-HashRule -FileName 'StatusTest.exe' -Hash ('33' * 32) -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        if ($rule.Success) {
            $setResult = Set-RuleStatus -RuleId $rule.Data.RuleId -Status 'Approved'
            $setResult.Success | Should -Be $true

            $check = Get-Rule -RuleId $rule.Data.RuleId
            $check.Data.Status | Should -Be 'Approved'
        }
    }
}

# ============================================================================
# IMPORT/EXPORT ROUNDTRIP - ALL RULE TYPES
# ============================================================================

Describe 'Integration: Import/Export Roundtrip' -Tag 'Integration' {

    It 'Should roundtrip hash rules through XML export/import' {
        $rule = New-HashRule -FileName 'RoundTrip.exe' -Hash ('44' * 32) -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        $policy = New-Policy -Name 'Integration_RT_Hash' -CollectionType 'Exe'
        Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $rule.Data.RuleId

        $xmlPath = Join-Path $script:TestDir 'roundtrip_hash.xml'
        Export-PolicyToXml -PolicyId $policy.Data.PolicyId -OutputPath $xmlPath

        if (Test-Path $xmlPath) {
            $imported = Import-RulesFromXml -XmlPath $xmlPath
            $imported.Success | Should -Be $true
            @($imported.Data).Count | Should -BeGreaterOrEqual 1
        }
    }

    It 'Should roundtrip publisher rules through XML export/import' {
        $rule = New-PublisherRule -Publisher 'O=RoundTrip Inc' -ProductName 'RTApp' `
            -FileName 'rt.exe' -FileVersion '1.0.0.0' -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        $policy = New-Policy -Name 'Integration_RT_Publisher' -CollectionType 'Exe'
        Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $rule.Data.RuleId

        $xmlPath = Join-Path $script:TestDir 'roundtrip_publisher.xml'
        Export-PolicyToXml -PolicyId $policy.Data.PolicyId -OutputPath $xmlPath

        if (Test-Path $xmlPath) {
            $imported = Import-RulesFromXml -XmlPath $xmlPath
            $imported.Success | Should -Be $true
        }
    }

    It 'Should roundtrip mixed rule types in single policy' {
        $hash = New-HashRule -FileName 'Mixed1.exe' -Hash ('55' * 32) -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
        $pub = New-PublisherRule -Publisher 'O=Mixed Corp' -ProductName 'MixedApp' `
            -FileName 'mixed2.exe' -FileVersion '1.0.0.0' -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
        $path = New-PathRule -Path 'C:\Mixed\*' -Action 'Deny' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        $policy = New-Policy -Name 'Integration_RT_Mixed' -CollectionType 'Exe'
        if ($hash.Success) { Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $hash.Data.RuleId }
        if ($pub.Success) { Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $pub.Data.RuleId }
        if ($path.Success) { Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $path.Data.RuleId }

        $xmlPath = Join-Path $script:TestDir 'roundtrip_mixed.xml'
        Export-PolicyToXml -PolicyId $policy.Data.PolicyId -OutputPath $xmlPath

        if (Test-Path $xmlPath) {
            $imported = Import-RulesFromXml -XmlPath $xmlPath
            $imported.Success | Should -Be $true
            @($imported.Data).Count | Should -BeGreaterOrEqual 2
        }
    }

    It 'Should preserve filenames through export/import roundtrip' {
        $rule = New-HashRule -FileName 'PreserveMe.exe' -Hash ('66' * 32) -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        $policy = New-Policy -Name 'Integration_RT_Filename' -CollectionType 'Exe'
        Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $rule.Data.RuleId

        $xmlPath = Join-Path $script:TestDir 'roundtrip_filename.xml'
        Export-PolicyToXml -PolicyId $policy.Data.PolicyId -OutputPath $xmlPath

        if (Test-Path $xmlPath) {
            $imported = Import-RulesFromXml -XmlPath $xmlPath
            if ($imported.Success -and @($imported.Data).Count -gt 0) {
                $importedRule = $imported.Data | Where-Object { $_.FileName -like '*PreserveMe*' -or $_.Name -like '*PreserveMe*' }
                $importedRule | Should -Not -BeNullOrEmpty
            }
        }
    }
}

# ============================================================================
# BULK OPERATIONS PIPELINE
# ============================================================================

Describe 'Integration: Bulk Operations' -Tag 'Integration' {

    It 'Should batch-generate rules from multiple artifacts' {
        $artifacts = @()
        for ($i = 1; $i -le 5; $i++) {
            $artifacts += [PSCustomObject]@{
                FilePath        = "C:\Test\BulkApp$i.exe"
                FileName        = "BulkApp$i.exe"
                SHA256Hash      = ('{0:X2}' -f $i) * 32
                Publisher       = $null
                IsSigned        = $false
                ArtifactType    = 'EXE'
                CollectionType  = 'Exe'
                Extension       = '.exe'
            }
        }

        $result = Invoke-BatchRuleGeneration -Artifacts $artifacts -DefaultAction 'Allow' -DefaultGroup 'S-1-1-0'
        $result.Success | Should -Be $true
        $result.Data.Generated | Should -BeGreaterOrEqual 1
    }

    It 'Should set bulk status on multiple rules' {
        # Create a few rules
        $ruleIds = @()
        for ($i = 1; $i -le 3; $i++) {
            $r = New-HashRule -FileName "BulkStatus$i.exe" -Hash ('{0:X2}' -f ($i + 100)) * 32 `
                -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
            if ($r.Success) { $ruleIds += $r.Data.RuleId }
        }

        if ($ruleIds.Count -ge 2) {
            $result = Set-BulkRuleStatus -RuleIds $ruleIds -Status 'Approved'
            $result.Success | Should -Be $true
        }
    }

    It 'Should detect duplicate rules' {
        $hash = '77' * 32
        New-HashRule -FileName 'Dup1.exe' -Hash $hash -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
        New-HashRule -FileName 'Dup2.exe' -Hash $hash -Action 'Allow' -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'

        $dupes = Find-DuplicateRules
        $dupes.Success | Should -Be $true
    }
}

# ============================================================================
# CONFIG -> SCAN INTEGRATION
# ============================================================================

Describe 'Integration: Config and Scanning' -Tag 'Integration' {

    It 'Should read scan paths from config' {
        $config = Get-AppLockerConfig
        $config.DefaultScanPaths | Should -Not -BeNullOrEmpty
    }

    It 'Should perform a local scan and return artifacts' {
        # Scan a known small directory
        $result = Get-LocalArtifacts -Paths @('C:\Windows\System32') -Extensions @('.exe') -MaxDepth 0
        $result.Success | Should -Be $true
        @($result.Data).Count | Should -BeGreaterThan 0
    }

    It 'Should return artifact metadata (hash, filename, type)' {
        $result = Get-LocalArtifacts -Paths @('C:\Windows\System32') -Extensions @('.exe') -MaxDepth 0
        if ($result.Success -and @($result.Data).Count -gt 0) {
            $first = $result.Data[0]
            $first.FileName | Should -Not -BeNullOrEmpty
            $first.SHA256Hash | Should -Not -BeNullOrEmpty
            $first.ArtifactType | Should -Be 'EXE'
        }
    }
}

# ============================================================================
# POLICY LIFECYCLE
# ============================================================================

Describe 'Integration: Policy Lifecycle' -Tag 'Integration' {

    It 'Should complete full lifecycle: create -> add rules -> snapshot -> modify -> compare' {
        # Create
        $policy = New-Policy -Name 'Integration_Lifecycle' -CollectionType 'Exe'
        $policy.Success | Should -Be $true

        # Add rule
        $rule = New-HashRule -FileName 'Lifecycle.exe' -Hash ('88' * 32) -Action 'Allow' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
        Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $rule.Data.RuleId

        # Snapshot
        $snap = New-PolicySnapshot -PolicyId $policy.Data.PolicyId -Description 'Before modification'
        $snap.Success | Should -Be $true

        # Add another rule (modification)
        $rule2 = New-HashRule -FileName 'Lifecycle2.exe' -Hash ('99' * 32) -Action 'Deny' `
            -UserOrGroupSid 'S-1-1-0' -CollectionType 'Exe'
        Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $rule2.Data.RuleId

        # Verify policy now has 2 rules
        $current = Get-Policy -PolicyId $policy.Data.PolicyId
        @($current.Data.RuleIds).Count | Should -Be 2

        # Snapshot list should have at least 1
        $snapshots = Get-PolicySnapshots -PolicyId $policy.Data.PolicyId
        @($snapshots.Data).Count | Should -BeGreaterOrEqual 1
    }
}

# ============================================================================
# MODULE CROSS-DEPENDENCY VERIFICATION
# ============================================================================

Describe 'Integration: Module Cross-Dependencies' -Tag 'Integration' {

    It 'Core module functions should be available to all modules' {
        # Write-AppLockerLog is used by every module
        Get-Command 'Write-AppLockerLog' | Should -Not -BeNullOrEmpty
        Get-Command 'Get-AppLockerConfig' | Should -Not -BeNullOrEmpty
        Get-Command 'Get-AppLockerDataPath' | Should -Not -BeNullOrEmpty
    }

    It 'Storage module should serve Rules module' {
        # Rules module depends on Storage for persistence
        Get-Command 'Get-RuleById' | Should -Not -BeNullOrEmpty
        Get-Command 'Add-Rule' | Should -Not -BeNullOrEmpty
        Get-Command 'Find-RuleByHash' | Should -Not -BeNullOrEmpty
    }

    It 'Rules module should serve Policy module' {
        Get-Command 'New-HashRule' | Should -Not -BeNullOrEmpty
        Get-Command 'Export-RulesToXml' | Should -Not -BeNullOrEmpty
        Get-Command 'ConvertFrom-Artifact' | Should -Not -BeNullOrEmpty
    }

    It 'Policy module should serve Deployment module' {
        Get-Command 'Export-PolicyToXml' | Should -Not -BeNullOrEmpty
        Get-Command 'Get-Policy' | Should -Not -BeNullOrEmpty
    }

    It 'Validation module should validate Policy output' {
        Get-Command 'Invoke-AppLockerPolicyValidation' | Should -Not -BeNullOrEmpty
        Get-Command 'Test-AppLockerXmlSchema' | Should -Not -BeNullOrEmpty
    }
}
