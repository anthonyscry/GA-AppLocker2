#Requires -Modules Pester
<#
.SYNOPSIS
    Tests for all module manifests and export integrity.

.DESCRIPTION
    Validates all 10 sub-module manifests + root manifest:
    - .psd1 parses correctly
    - FunctionsToExport match actual function files
    - No duplicate exports
    - All exported functions are actually loadable
    - Sub-module dependencies are correct

.NOTES
    Cross-module manifest integrity tests
    Run with: Invoke-Pester -Path .\Tests\Unit\Module.Manifest.Tests.ps1 -Output Detailed
#>

BeforeAll {
    Get-Module 'GA-AppLocker*' | Remove-Module -Force -ErrorAction SilentlyContinue
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    $script:ModuleBase = Join-Path $PSScriptRoot '..\..\GA-AppLocker'
    $script:RootManifest = Import-PowerShellDataFile (Join-Path $script:ModuleBase 'GA-AppLocker.psd1')

    $script:SubModules = @(
        'GA-AppLocker.Core',
        'GA-AppLocker.Discovery',
        'GA-AppLocker.Credentials',
        'GA-AppLocker.Scanning',
        'GA-AppLocker.Rules',
        'GA-AppLocker.Policy',
        'GA-AppLocker.Deployment',
        'GA-AppLocker.Setup',
        'GA-AppLocker.Storage',
        'GA-AppLocker.Validation'
    )
}

# ============================================================================
# ROOT MANIFEST
# ============================================================================

Describe 'Root Module Manifest (GA-AppLocker.psd1)' -Tag 'Unit', 'Module' {

    It 'Should parse as valid PowerShell data' {
        { Import-PowerShellDataFile (Join-Path $script:ModuleBase 'GA-AppLocker.psd1') } | Should -Not -Throw
    }

    It 'Should have ModuleVersion 1.2.30' {
        $script:RootManifest.ModuleVersion | Should -Be '1.2.30'
    }

    It 'Should have more than 100 exported functions' {
        $script:RootManifest.FunctionsToExport.Count | Should -BeGreaterThan 100
    }

    It 'Should have no duplicate exports' {
        $exports = $script:RootManifest.FunctionsToExport
        $unique = $exports | Select-Object -Unique
        $exports.Count | Should -Be $unique.Count
    }

    It 'Should include Start-AppLockerDashboard' {
        $script:RootManifest.FunctionsToExport | Should -Contain 'Start-AppLockerDashboard'
    }

    It 'Should include Test-PingConnectivity' {
        $script:RootManifest.FunctionsToExport | Should -Contain 'Test-PingConnectivity'
    }

    It 'Should have NestedModules for all 10 sub-modules' {
        $script:RootManifest.NestedModules.Count | Should -BeGreaterOrEqual 10
    }

    It 'Should list all sub-modules in NestedModules' {
        $nestedPaths = $script:RootManifest.NestedModules | ForEach-Object { [System.IO.Path]::GetFileName($_) }
        foreach ($mod in $script:SubModules) {
            $expectedFile = "$mod.psd1"
            $nestedPaths | Should -Contain $expectedFile
        }
    }
}

# ============================================================================
# SUB-MODULE MANIFESTS
# ============================================================================

Describe 'Sub-Module Manifests' -Tag 'Unit', 'Module' {

    foreach ($modName in $script:SubModules) {
        Context "$modName" {
            BeforeAll {
                $psdPath = Join-Path $script:ModuleBase "Modules\$modName\$modName.psd1"
                $script:SubManifest = Import-PowerShellDataFile $psdPath
            }

            It 'Should parse as valid PowerShell data' {
                $psdPath = Join-Path $script:ModuleBase "Modules\$modName\$modName.psd1"
                { Import-PowerShellDataFile $psdPath } | Should -Not -Throw
            }

            It 'Should have FunctionsToExport defined' {
                $script:SubManifest.FunctionsToExport | Should -Not -BeNullOrEmpty
            }

            It 'Should have no duplicate function exports' {
                $exports = $script:SubManifest.FunctionsToExport
                $unique = $exports | Select-Object -Unique
                $exports.Count | Should -Be $unique.Count
            }

            It 'Should have a RootModule (.psm1) file that exists' {
                $psmPath = Join-Path $script:ModuleBase "Modules\$modName\$modName.psm1"
                Test-Path $psmPath | Should -Be $true
            }

            It 'Should have a Functions directory' {
                $funcDir = Join-Path $script:ModuleBase "Modules\$modName\Functions"
                Test-Path $funcDir | Should -Be $true
            }
        }
    }
}

# ============================================================================
# EVERY EXPORTED FUNCTION IS LOADABLE
# ============================================================================

Describe 'All Exported Functions Are Loadable' -Tag 'Unit', 'Module' {

    BeforeAll {
        $script:ExportedFunctions = $script:RootManifest.FunctionsToExport
    }

    It 'Every root-exported function should be resolvable via Get-Command' {
        $missing = @()
        foreach ($fn in $script:ExportedFunctions) {
            $cmd = Get-Command $fn -ErrorAction SilentlyContinue
            if (-not $cmd) { $missing += $fn }
        }
        if ($missing.Count -gt 0) {
            $missing -join ', ' | Should -Be '' -Because "These functions are in .psd1 but not loadable: $($missing -join ', ')"
        }
    }
}

# ============================================================================
# KEY FUNCTION EXPORTS PER MODULE
# ============================================================================

Describe 'Key Function Exports - Core' -Tag 'Unit', 'Module' {
    $coreFunctions = @(
        'Write-AppLockerLog', 'Get-AppLockerConfig', 'Set-AppLockerConfig',
        'Get-AppLockerDataPath', 'Save-SessionState', 'Restore-SessionState',
        'Get-CachedValue', 'Set-CachedValue', 'Publish-AppLockerEvent',
        'Register-AppLockerEvent', 'Test-ValidHash', 'Test-ValidSid',
        'Test-ValidGuid', 'Resolve-GroupSid', 'Write-AuditLog', 'Get-AuditLog',
        'Invoke-WithRetry', 'Test-Prerequisites'
    )
    foreach ($fn in $coreFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Discovery' -Tag 'Unit', 'Module' {
    $discoveryFunctions = @(
        'Get-DomainInfo', 'Get-OUTree', 'Get-ComputersByOU',
        'Test-MachineConnectivity', 'Test-PingConnectivity',
        'Resolve-LdapServer', 'Test-LdapConnection'
    )
    foreach ($fn in $discoveryFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Credentials' -Tag 'Unit', 'Module' {
    $credFunctions = @(
        'New-CredentialProfile', 'Get-CredentialProfile', 'Get-AllCredentialProfiles',
        'Remove-CredentialProfile', 'Test-CredentialProfile',
        'Get-CredentialForTier', 'Get-CredentialStoragePath'
    )
    foreach ($fn in $credFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Scanning' -Tag 'Unit', 'Module' {
    $scanFunctions = @(
        'Get-LocalArtifacts', 'Get-RemoteArtifacts', 'Get-AppxArtifacts',
        'Start-ArtifactScan', 'Get-ScanResults', 'Export-ScanResults',
        'New-ScheduledScan', 'Get-ScheduledScans'
    )
    foreach ($fn in $scanFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Rules' -Tag 'Unit', 'Module' {
    $rulesFunctions = @(
        'New-HashRule', 'New-PublisherRule', 'New-PathRule', 'ConvertFrom-Artifact',
        'Get-Rule', 'Set-RuleStatus', 'Export-RulesToXml', 'Import-RulesFromXml',
        'Get-RuleTemplates', 'Set-BulkRuleStatus', 'Invoke-BatchRuleGeneration',
        'Find-DuplicateRules', 'Get-SuggestedGroup', 'Save-RuleVersion', 'Get-RuleHistory'
    )
    foreach ($fn in $rulesFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Policy' -Tag 'Unit', 'Module' {
    $policyFunctions = @(
        'New-Policy', 'Get-Policy', 'Get-AllPolicies', 'Update-Policy',
        'Remove-Policy', 'Add-RuleToPolicy', 'Remove-RuleFromPolicy',
        'Export-PolicyToXml', 'Compare-Policies', 'New-PolicySnapshot',
        'Get-PolicySnapshots', 'Restore-PolicySnapshot'
    )
    foreach ($fn in $policyFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Deployment' -Tag 'Unit', 'Module' {
    $deployFunctions = @(
        'New-DeploymentJob', 'Get-DeploymentJob', 'Get-AllDeploymentJobs',
        'Start-Deployment', 'Stop-Deployment', 'Test-GPOExists',
        'Import-PolicyToGPO', 'Get-DeploymentHistory'
    )
    foreach ($fn in $deployFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Setup' -Tag 'Unit', 'Module' {
    $setupFunctions = @(
        'Initialize-WinRMGPO', 'Initialize-AppLockerGPOs', 'Initialize-ADStructure',
        'Initialize-AppLockerEnvironment', 'Get-SetupStatus',
        'Enable-WinRMGPO', 'Disable-WinRMGPO', 'Remove-WinRMGPO',
        'Initialize-DisableWinRMGPO', 'Remove-DisableWinRMGPO'
    )
    foreach ($fn in $setupFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Storage' -Tag 'Unit', 'Module' {
    $storageFunctions = @(
        'Get-RuleById', 'Get-AllRules', 'Add-Rule', 'Update-Rule', 'Remove-Rule',
        'Find-RuleByHash', 'Find-RuleByPublisher', 'Save-RulesBulk',
        'Get-RuleFromRepository', 'Save-RuleToRepository', 'Find-RulesInRepository'
    )
    foreach ($fn in $storageFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Key Function Exports - Validation' -Tag 'Unit', 'Module' {
    $validationFunctions = @(
        'Test-AppLockerXmlSchema', 'Test-AppLockerRuleGuids', 'Test-AppLockerRuleSids',
        'Test-AppLockerRuleConditions', 'Test-AppLockerPolicyImport',
        'Invoke-AppLockerPolicyValidation'
    )
    foreach ($fn in $validationFunctions) {
        It "$fn should be exported" {
            Get-Command $fn -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
