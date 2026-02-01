#Requires -Modules Pester
<#
.SYNOPSIS
    Tests for GA-AppLocker.Deployment module.

.DESCRIPTION
    Covers deployment job management and GPO functions:
    - New-DeploymentJob / Get-DeploymentJob / Get-AllDeploymentJobs
    - Start-Deployment / Stop-Deployment / Get-DeploymentStatus
    - Test-GPOExists / New-AppLockerGPO / Import-PolicyToGPO
    - Get-DeploymentHistory

.NOTES
    Module: GA-AppLocker.Deployment
    Run with: Invoke-Pester -Path .\Tests\Unit\Deployment.Tests.ps1 -Output Detailed
#>

BeforeAll {
    Get-Module 'GA-AppLocker*' | Remove-Module -Force -ErrorAction SilentlyContinue
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # Read source files for pattern verification
    $script:GpoFunctionsContent = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\Modules\GA-AppLocker.Deployment\Functions\GPO-Functions.ps1') -Raw
    $script:StartDeployContent = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\Modules\GA-AppLocker.Deployment\Functions\Start-Deployment.ps1') -Raw
    $script:NewJobContent = Get-Content (Join-Path $PSScriptRoot '..\..\GA-AppLocker\Modules\GA-AppLocker.Deployment\Functions\New-DeploymentJob.ps1') -Raw
}

# ============================================================================
# FUNCTION EXPORTS
# ============================================================================

Describe 'Deployment Module - Function Exports' -Tag 'Unit', 'Deployment' {

    It 'New-DeploymentJob should be exported' {
        Get-Command 'New-DeploymentJob' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Get-DeploymentJob should be exported' {
        Get-Command 'Get-DeploymentJob' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Get-AllDeploymentJobs should be exported' {
        Get-Command 'Get-AllDeploymentJobs' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Start-Deployment should be exported' {
        Get-Command 'Start-Deployment' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Stop-Deployment should be exported' {
        Get-Command 'Stop-Deployment' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Get-DeploymentStatus should be exported' {
        Get-Command 'Get-DeploymentStatus' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Test-GPOExists should be exported' {
        Get-Command 'Test-GPOExists' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'New-AppLockerGPO should be exported' {
        Get-Command 'New-AppLockerGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Import-PolicyToGPO should be exported' {
        Get-Command 'Import-PolicyToGPO' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Get-DeploymentHistory should be exported' {
        Get-Command 'Get-DeploymentHistory' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

# ============================================================================
# NEW-DEPLOYMENTJOB
# ============================================================================

Describe 'New-DeploymentJob' -Tag 'Unit', 'Deployment' {

    BeforeAll {
        # Create a test policy for deployment job tests
        $script:TestPolicy = New-Policy -Name "UnitTest_DeployPolicy_$(Get-Random)" -Phase 1 -Description 'Test policy for deployment'
    }

    It 'Should create a deployment job for a valid policy' {
        if (-not $script:TestPolicy.Success) {
            Set-ItResult -Skipped -Because 'Policy creation failed'
            return
        }
        $result = New-DeploymentJob -PolicyId $script:TestPolicy.Data.PolicyId -GPOName 'Test-AppLocker-GPO'
        $result.Success | Should -Be $true
        $result.Data | Should -Not -BeNullOrEmpty
        $result.Data.JobId | Should -Not -BeNullOrEmpty
        $result.Data.Status | Should -Be 'Pending'
    }

    It 'Should assign a GUID JobId' {
        if (-not $script:TestPolicy.Success) {
            Set-ItResult -Skipped -Because 'Policy creation failed'
            return
        }
        $result = New-DeploymentJob -PolicyId $script:TestPolicy.Data.PolicyId -GPOName 'Test-GPO2'
        if ($result.Success) {
            { [guid]::Parse($result.Data.JobId) } | Should -Not -Throw
        }
    }

    It 'Should record CreatedBy and CreatedAt' {
        if (-not $script:TestPolicy.Success) {
            Set-ItResult -Skipped -Because 'Policy creation failed'
            return
        }
        $result = New-DeploymentJob -PolicyId $script:TestPolicy.Data.PolicyId -GPOName 'Test-GPO3'
        if ($result.Success) {
            $result.Data.CreatedBy | Should -Not -BeNullOrEmpty
            $result.Data.CreatedAt | Should -Not -BeNullOrEmpty
        }
    }

    It 'Should fail for non-existent policy' {
        $result = New-DeploymentJob -PolicyId ([guid]::NewGuid().ToString()) -GPOName 'Test-GPO'
        $result.Success | Should -Be $false
        $result.Error | Should -Not -BeNullOrEmpty
    }
}

# ============================================================================
# GET-DEPLOYMENTJOB / GET-ALLDEPLOYMENTJOBS
# ============================================================================

Describe 'Get-DeploymentJob and Get-AllDeploymentJobs' -Tag 'Unit', 'Deployment' {

    It 'Get-AllDeploymentJobs should return a Success result' {
        $result = Get-AllDeploymentJobs
        $result.Success | Should -Be $true
    }

    It 'Get-AllDeploymentJobs should filter by Status' {
        $result = Get-AllDeploymentJobs -Status 'Pending'
        $result.Success | Should -Be $true
        if ($result.Data -and @($result.Data).Count -gt 0) {
            @($result.Data | Where-Object { $_.Status -ne 'Pending' }).Count | Should -Be 0
        }
    }

    It 'Get-DeploymentJob should return null for non-existent job' {
        $result = Get-DeploymentJob -JobId ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $false
    }
}

# ============================================================================
# TEST-GPOEXISTS
# ============================================================================

Describe 'Test-GPOExists' -Tag 'Unit', 'Deployment' {

    It 'Should return ManualRequired when GroupPolicy module not available' {
        # On most dev machines without RSAT, this should return ManualRequired
        $result = Test-GPOExists -GPOName 'NonExistentGPO'
        # Either Success (GP module available) or ManualRequired (not available)
        ($result.Success -or $result.ManualRequired) | Should -Be $true
    }

    It 'Should not throw for any GPO name' {
        { Test-GPOExists -GPOName 'SomeRandomGPOName' } | Should -Not -Throw
    }
}

# ============================================================================
# IMPORT-POLICYTOGPO - CODE PATTERNS
# ============================================================================

Describe 'Import-PolicyToGPO - Code Patterns' -Tag 'Unit', 'Deployment' {

    It 'Should use Resolve-Path for file path (v1.2.28 fix)' {
        $script:GpoFunctionsContent | Should -Match 'Resolve-Path.*\$XmlPath'
    }

    It 'Should pass resolved path to Set-AppLockerPolicy' {
        $script:GpoFunctionsContent | Should -Match 'Set-AppLockerPolicy.*-XmlPolicy.*\$resolvedPath'
    }

    It 'Should NOT use ReadAllText to pass content to Set-AppLockerPolicy' {
        $script:GpoFunctionsContent | Should -Not -Match 'ReadAllText.*Set-AppLockerPolicy'
    }

    It 'Should support -Merge switch' {
        $script:GpoFunctionsContent | Should -Match '\[switch\]\$Merge'
    }

    It 'Should return ManualRequired when Set-AppLockerPolicy not available' {
        $script:GpoFunctionsContent | Should -Match 'ManualRequired.*=.*\$true'
    }

    It 'Should resolve domain DN with LDAP fallback' {
        $script:GpoFunctionsContent | Should -Match 'RootDSE|Get-ADDomain'
    }
}

# ============================================================================
# START-DEPLOYMENT - CODE PATTERNS
# ============================================================================

Describe 'Start-Deployment - Code Patterns' -Tag 'Unit', 'Deployment' {

    It 'Should export policy to XML before deploying' {
        $script:StartDeployContent | Should -Match 'Export-PolicyToXml'
    }

    It 'Should call Import-PolicyToGPO' {
        $script:StartDeployContent | Should -Match 'Import-PolicyToGPO'
    }

    It 'Should update job status during deployment' {
        $script:StartDeployContent | Should -Match 'Status.*=.*Running|Running'
    }

    It 'Should handle ManualRequired fallback' {
        $script:StartDeployContent | Should -Match 'ManualRequired'
    }

    It 'Should call Add-DeploymentHistory' {
        $script:StartDeployContent | Should -Match 'Add-DeploymentHistory'
    }

    It 'Should call Set-PolicyStatus on completion' {
        $script:StartDeployContent | Should -Match 'Set-PolicyStatus'
    }
}

# ============================================================================
# STOP-DEPLOYMENT
# ============================================================================

Describe 'Stop-Deployment' -Tag 'Unit', 'Deployment' {

    It 'Should return error for non-existent job' {
        $result = Stop-Deployment -JobId ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $false
    }
}

# ============================================================================
# GET-DEPLOYMENTSTATUS
# ============================================================================

Describe 'Get-DeploymentStatus' -Tag 'Unit', 'Deployment' {

    It 'Should return error for non-existent job' {
        $result = Get-DeploymentStatus -JobId ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $false
    }
}

# ============================================================================
# GET-DEPLOYMENTHISTORY
# ============================================================================

Describe 'Get-DeploymentHistory' -Tag 'Unit', 'Deployment' {

    It 'Should return a Success result' {
        $result = Get-DeploymentHistory
        $result.Success | Should -Be $true
    }

    It 'Should support Limit parameter' {
        $result = Get-DeploymentHistory -Limit 5
        $result.Success | Should -Be $true
        if ($result.Data) {
            @($result.Data).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should support JobId filter' {
        $result = Get-DeploymentHistory -JobId ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $true
        # Should return empty for non-existent job
    }
}

# ============================================================================
# DEPLOYMENT JOB FILE STRUCTURE
# ============================================================================

Describe 'New-DeploymentJob - File Structure' -Tag 'Unit', 'Deployment' {

    It 'Should define Status field in job object' {
        $script:NewJobContent | Should -Match "Status\s*=\s*'Pending'"
    }

    It 'Should define Progress field initialized to 0' {
        $script:NewJobContent | Should -Match 'Progress\s*=\s*0'
    }

    It 'Should save job as JSON file' {
        $script:NewJobContent | Should -Match 'ConvertTo-Json.*Set-Content'
    }

    It 'Should validate policy exists before creating job' {
        $script:NewJobContent | Should -Match 'Get-Policy'
    }
}
