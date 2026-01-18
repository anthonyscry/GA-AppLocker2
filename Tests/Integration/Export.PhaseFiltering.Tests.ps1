#Requires -Modules Pester
<#
.SYNOPSIS
    Integration tests for Phase-Based Export filtering in GA-AppLocker.

.DESCRIPTION
    Tests the following behaviors:
    - Phase 1 exports only EXE rules
    - Phase 2 exports EXE + Script rules
    - Phase 3 exports EXE + Script + MSI rules
    - Phase 4 exports all rule types (EXE, Script, MSI, DLL, Appx)
    - PhaseOverride parameter works correctly
    - Exported XML passes AppLocker schema validation

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Integration\Export.PhaseFiltering.Tests.ps1 -Output Detailed
#>

BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # Create test directory for exports
    $script:testExportPath = Join-Path $env:TEMP "GA-AppLocker-Tests-$(Get-Random)"
    New-Item -Path $script:testExportPath -ItemType Directory -Force | Out-Null

    # Track created resources for cleanup
    $script:createdRuleIds = @()
    $script:createdPolicyId = $null
}

AfterAll {
    # Cleanup test exports
    if (Test-Path $script:testExportPath) {
        Remove-Item -Path $script:testExportPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Cleanup created rules
    foreach ($ruleId in $script:createdRuleIds) {
        Remove-Rule -Id $ruleId -Force -ErrorAction SilentlyContinue | Out-Null
    }

    # Cleanup created policy
    if ($script:createdPolicyId) {
        Remove-Policy -PolicyId $script:createdPolicyId -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

Describe 'Export-PolicyToXml Phase Filtering' -Tag 'Integration', 'Export', 'Phase' {
    
    BeforeAll {
        # Create one rule of each collection type
        $script:rules = @{}

        # EXE rule (Publisher)
        $exeResult = New-PublisherRule -PublisherName 'O=TEST EXE PUBLISHER' -ProductName 'TestExeProduct' -CollectionType Exe -Save
        $script:rules['Exe'] = $exeResult.Data
        $script:createdRuleIds += $exeResult.Data.Id

        # Script rule (Path)
        $scriptResult = New-PathRule -Path '%WINDIR%\TestScript.ps1' -CollectionType Script -Save
        $script:rules['Script'] = $scriptResult.Data
        $script:createdRuleIds += $scriptResult.Data.Id

        # MSI rule (Hash)
        $msiResult = New-HashRule -Hash ('A' * 64) -SourceFileName 'TestInstaller.msi' -SourceFileLength 1024 -CollectionType Msi -Save
        $script:rules['Msi'] = $msiResult.Data
        $script:createdRuleIds += $msiResult.Data.Id

        # DLL rule (Path)
        $dllResult = New-PathRule -Path '%PROGRAMFILES%\TestApp\*.dll' -CollectionType Dll -Save
        $script:rules['Dll'] = $dllResult.Data
        $script:createdRuleIds += $dllResult.Data.Id

        # Appx rule (Publisher)
        $appxResult = New-PublisherRule -PublisherName 'O=TEST APPX PUBLISHER' -ProductName 'TestAppxApp' -CollectionType Appx -Save
        $script:rules['Appx'] = $appxResult.Data
        $script:createdRuleIds += $appxResult.Data.Id

        # Create policy with all rules
        $policyResult = New-Policy -Name "PhaseFilterTest_$(Get-Random)" -Phase 4
        $script:createdPolicyId = $policyResult.Data.PolicyId

        # Add all rules to policy
        foreach ($rule in $script:rules.Values) {
            Add-RuleToPolicy -PolicyId $script:createdPolicyId -RuleId $rule.Id | Out-Null
        }

        # Set all rules to Approved status (required for export)
        foreach ($rule in $script:rules.Values) {
            Set-RuleStatus -Id $rule.Id -Status Approved | Out-Null
        }
    }

    Context 'Phase 1 Export (EXE Only)' {
        BeforeAll {
            $script:phase1Path = Join-Path $script:testExportPath 'phase1.xml'
            $script:phase1Result = Export-PolicyToXml -PolicyId $script:createdPolicyId -OutputPath $script:phase1Path -PhaseOverride 1
        }

        It 'Exports successfully' {
            $script:phase1Result.Success | Should -BeTrue
        }

        It 'Reports correct rule count' {
            $script:phase1Result.Data.RuleCount | Should -Be 1
            $script:phase1Result.Data.RuleBreakdown.Exe | Should -Be 1
            $script:phase1Result.Data.RuleBreakdown.Script | Should -Be 0
            $script:phase1Result.Data.RuleBreakdown.Msi | Should -Be 0
            $script:phase1Result.Data.RuleBreakdown.Dll | Should -Be 0
            $script:phase1Result.Data.RuleBreakdown.Appx | Should -Be 0
        }

        It 'Sets enforcement to AuditOnly' {
            $script:phase1Result.Data.EnforcementMode | Should -Be 'AuditOnly'
        }

        It 'XML contains only Exe rules' {
            $xml = [xml](Get-Content $script:phase1Path)
            
            # Exe collection should have rules
            $exeRules = $xml.SelectNodes("//RuleCollection[@Type='Exe']/*")
            $exeRules.Count | Should -BeGreaterThan 0

            # All other collections should be empty
            $scriptRules = $xml.SelectNodes("//RuleCollection[@Type='Script']/*")
            $scriptRules.Count | Should -Be 0

            $msiRules = $xml.SelectNodes("//RuleCollection[@Type='Msi']/*")
            $msiRules.Count | Should -Be 0

            $dllRules = $xml.SelectNodes("//RuleCollection[@Type='Dll']/*")
            $dllRules.Count | Should -Be 0

            $appxRules = $xml.SelectNodes("//RuleCollection[@Type='Appx']/*")
            $appxRules.Count | Should -Be 0
        }
    }

    Context 'Phase 2 Export (EXE + Script)' {
        BeforeAll {
            $script:phase2Path = Join-Path $script:testExportPath 'phase2.xml'
            $script:phase2Result = Export-PolicyToXml -PolicyId $script:createdPolicyId -OutputPath $script:phase2Path -PhaseOverride 2
        }

        It 'Exports successfully' {
            $script:phase2Result.Success | Should -BeTrue
        }

        It 'Reports correct rule count' {
            $script:phase2Result.Data.RuleCount | Should -Be 2
            $script:phase2Result.Data.RuleBreakdown.Exe | Should -Be 1
            $script:phase2Result.Data.RuleBreakdown.Script | Should -Be 1
            $script:phase2Result.Data.RuleBreakdown.Msi | Should -Be 0
        }

        It 'Sets enforcement to AuditOnly' {
            $script:phase2Result.Data.EnforcementMode | Should -Be 'AuditOnly'
        }

        It 'XML contains only Exe and Script rules' {
            $xml = [xml](Get-Content $script:phase2Path)
            
            $xml.SelectNodes("//RuleCollection[@Type='Exe']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Script']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Msi']/*").Count | Should -Be 0
            $xml.SelectNodes("//RuleCollection[@Type='Dll']/*").Count | Should -Be 0
            $xml.SelectNodes("//RuleCollection[@Type='Appx']/*").Count | Should -Be 0
        }
    }

    Context 'Phase 3 Export (EXE + Script + MSI)' {
        BeforeAll {
            $script:phase3Path = Join-Path $script:testExportPath 'phase3.xml'
            $script:phase3Result = Export-PolicyToXml -PolicyId $script:createdPolicyId -OutputPath $script:phase3Path -PhaseOverride 3
        }

        It 'Exports successfully' {
            $script:phase3Result.Success | Should -BeTrue
        }

        It 'Reports correct rule count' {
            $script:phase3Result.Data.RuleCount | Should -Be 3
            $script:phase3Result.Data.RuleBreakdown.Exe | Should -Be 1
            $script:phase3Result.Data.RuleBreakdown.Script | Should -Be 1
            $script:phase3Result.Data.RuleBreakdown.Msi | Should -Be 1
            $script:phase3Result.Data.RuleBreakdown.Dll | Should -Be 0
        }

        It 'Sets enforcement to AuditOnly' {
            $script:phase3Result.Data.EnforcementMode | Should -Be 'AuditOnly'
        }

        It 'XML contains Exe, Script, and Msi rules only' {
            $xml = [xml](Get-Content $script:phase3Path)
            
            $xml.SelectNodes("//RuleCollection[@Type='Exe']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Script']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Msi']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Dll']/*").Count | Should -Be 0
            $xml.SelectNodes("//RuleCollection[@Type='Appx']/*").Count | Should -Be 0
        }
    }

    Context 'Phase 4 Export (All Rules)' {
        BeforeAll {
            $script:phase4Path = Join-Path $script:testExportPath 'phase4.xml'
            $script:phase4Result = Export-PolicyToXml -PolicyId $script:createdPolicyId -OutputPath $script:phase4Path -PhaseOverride 4
        }

        It 'Exports successfully' {
            $script:phase4Result.Success | Should -BeTrue
        }

        It 'Reports correct rule count' {
            $script:phase4Result.Data.RuleCount | Should -Be 5
            $script:phase4Result.Data.RuleBreakdown.Exe | Should -Be 1
            $script:phase4Result.Data.RuleBreakdown.Script | Should -Be 1
            $script:phase4Result.Data.RuleBreakdown.Msi | Should -Be 1
            $script:phase4Result.Data.RuleBreakdown.Dll | Should -Be 1
            $script:phase4Result.Data.RuleBreakdown.Appx | Should -Be 1
        }

        It 'XML contains all rule types' {
            $xml = [xml](Get-Content $script:phase4Path)
            
            $xml.SelectNodes("//RuleCollection[@Type='Exe']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Script']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Msi']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Dll']/*").Count | Should -BeGreaterThan 0
            $xml.SelectNodes("//RuleCollection[@Type='Appx']/*").Count | Should -BeGreaterThan 0
        }
    }

    Context 'Policy Phase vs PhaseOverride' {
        It 'Uses policy Phase when PhaseOverride not specified' {
            # Create Phase 2 policy
            $phase2Policy = New-Policy -Name "Phase2PolicyTest_$(Get-Random)" -Phase 2
            Add-RuleToPolicy -PolicyId $phase2Policy.Data.PolicyId -RuleId $script:rules['Exe'].Id | Out-Null
            Add-RuleToPolicy -PolicyId $phase2Policy.Data.PolicyId -RuleId $script:rules['Script'].Id | Out-Null
            Add-RuleToPolicy -PolicyId $phase2Policy.Data.PolicyId -RuleId $script:rules['Msi'].Id | Out-Null

            try {
                $exportPath = Join-Path $script:testExportPath 'phase2policy.xml'
                $result = Export-PolicyToXml -PolicyId $phase2Policy.Data.PolicyId -OutputPath $exportPath
                # No PhaseOverride - should use policy's Phase 2
                
                $result.Data.Phase | Should -Be 2
                $result.Data.RuleBreakdown.Msi | Should -Be 0 -Because 'Phase 2 excludes MSI'
            }
            finally {
                Remove-Policy -PolicyId $phase2Policy.Data.PolicyId -Force | Out-Null
            }
        }

        It 'PhaseOverride takes precedence over policy Phase' {
            # Policy is Phase 4, but override to Phase 1
            $exportPath = Join-Path $script:testExportPath 'override.xml'
            $result = Export-PolicyToXml -PolicyId $script:createdPolicyId -OutputPath $exportPath -PhaseOverride 1
            
            $result.Data.Phase | Should -Be 1
            $result.Data.RuleCount | Should -Be 1
        }
    }
}

Describe 'Export XML Schema Validation' -Tag 'Integration', 'Export', 'Schema' {

    BeforeAll {
        # Create a simple policy with one rule for schema testing
        $rule = New-PublisherRule -PublisherName 'O=SCHEMA TEST' -ProductName 'Test' -CollectionType Exe -Save
        $script:schemaTestRuleId = $rule.Data.Id
        Set-RuleStatus -Id $rule.Data.Id -Status Approved | Out-Null

        $policy = New-Policy -Name "SchemaTest_$(Get-Random)" -Phase 1
        $script:schemaTestPolicyId = $policy.Data.PolicyId
        Add-RuleToPolicy -PolicyId $policy.Data.PolicyId -RuleId $rule.Data.Id | Out-Null

        $script:schemaTestPath = Join-Path $env:TEMP "schema-test-$(Get-Random).xml"
        Export-PolicyToXml -PolicyId $policy.Data.PolicyId -OutputPath $script:schemaTestPath | Out-Null
    }

    AfterAll {
        Remove-Item -Path $script:schemaTestPath -Force -ErrorAction SilentlyContinue
        Remove-Policy -PolicyId $script:schemaTestPolicyId -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Rule -Id $script:schemaTestRuleId -Force -ErrorAction SilentlyContinue | Out-Null
    }

    It 'Exported XML is well-formed' {
        { [xml](Get-Content $script:schemaTestPath) } | Should -Not -Throw
    }

    It 'XML has AppLockerPolicy root element' {
        $xml = [xml](Get-Content $script:schemaTestPath)
        $xml.DocumentElement.Name | Should -Be 'AppLockerPolicy'
    }

    It 'XML has Version attribute' {
        $xml = [xml](Get-Content $script:schemaTestPath)
        $xml.AppLockerPolicy.Version | Should -Be '1'
    }

    It 'XML has all 5 RuleCollection elements' {
        $xml = [xml](Get-Content $script:schemaTestPath)
        $collections = $xml.SelectNodes("//RuleCollection")
        $collections.Count | Should -Be 5

        $types = $collections | ForEach-Object { $_.Type }
        $types | Should -Contain 'Exe'
        $types | Should -Contain 'Dll'
        $types | Should -Contain 'Msi'
        $types | Should -Contain 'Script'
        $types | Should -Contain 'Appx'
    }

    It 'RuleCollection has EnforcementMode attribute' {
        $xml = [xml](Get-Content $script:schemaTestPath)
        $exeCollection = $xml.SelectSingleNode("//RuleCollection[@Type='Exe']")
        $exeCollection.EnforcementMode | Should -BeIn @('NotConfigured', 'AuditOnly', 'Enabled')
    }

    It 'FilePublisherRule has required attributes' {
        $xml = [xml](Get-Content $script:schemaTestPath)
        $rule = $xml.SelectSingleNode("//FilePublisherRule")
        
        $rule.Id | Should -Not -BeNullOrEmpty
        $rule.Name | Should -Not -BeNullOrEmpty
        $rule.UserOrGroupSid | Should -Not -BeNullOrEmpty
        $rule.Action | Should -BeIn @('Allow', 'Deny')
    }

    It 'Passes Windows AppLocker policy validation' -Skip:(-not (Get-Command Get-AppLockerPolicy -ErrorAction SilentlyContinue)) {
        # This test only runs on systems with AppLocker cmdlets
        $validationResult = Get-AppLockerPolicy -Xml -Path $script:schemaTestPath -ErrorAction SilentlyContinue
        $? | Should -BeTrue -Because 'Get-AppLockerPolicy should parse the XML without errors'
    }
}

Describe 'Export Backward Compatibility' -Tag 'Integration', 'Export', 'BackwardCompat' {

    BeforeAll {
        # Create a rule to use for legacy policy test
        $rule = New-PublisherRule -PublisherName 'O=LEGACY COMPAT TEST' -ProductName 'Test' -CollectionType Exe -Save
        $script:legacyTestRuleId = $rule.Data.Id
        Set-RuleStatus -Id $rule.Data.Id -Status Approved | Out-Null
    }

    AfterAll {
        Remove-Rule -Id $script:legacyTestRuleId -Force -ErrorAction SilentlyContinue | Out-Null
    }

    It 'Exports policy without Phase field (defaults to Phase 4)' {
        # Create a legacy-style policy without Phase field
        $legacyPolicy = @{
            PolicyId        = [guid]::NewGuid().ToString()
            Name            = 'LegacyExportTest'
            Description     = 'No Phase field'
            EnforcementMode = 'AuditOnly'
            Status          = 'Active'
            RuleIds         = @($script:legacyTestRuleId)  # Include a rule so export can succeed
            TargetOUs       = @()
            TargetGPO       = $null
            CreatedAt       = (Get-Date).ToString('o')
            ModifiedAt      = (Get-Date).ToString('o')
            CreatedBy       = $env:USERNAME
            Version         = 1
            # NOTE: No Phase field - simulating legacy policy
        }

        $dataPath = Get-AppLockerDataPath
        $policiesPath = Join-Path $dataPath 'Policies'
        $policyFile = Join-Path $policiesPath "$($legacyPolicy.PolicyId).json"
        $legacyPolicy | ConvertTo-Json -Depth 5 | Set-Content -Path $policyFile -Encoding UTF8

        try {
            $exportPath = Join-Path $env:TEMP "legacy-export-$(Get-Random).xml"
            $result = Export-PolicyToXml -PolicyId $legacyPolicy.PolicyId -OutputPath $exportPath

            # Should succeed
            $result.Success | Should -BeTrue
            # Should default to Phase 4 (no filtering)
            $result.Data.Phase | Should -Be 4

            Remove-Item -Path $exportPath -Force -ErrorAction SilentlyContinue
        }
        finally {
            Remove-Item -Path $policyFile -Force -ErrorAction SilentlyContinue
        }
    }
}
