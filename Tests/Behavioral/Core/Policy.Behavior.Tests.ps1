#Requires -Modules Pester

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    $hash = (([guid]::NewGuid().ToString('N')) + ([guid]::NewGuid().ToString('N'))).Substring(0,64).ToUpper()
    $script:ruleId = $null
    $script:policyId = $null
    $script:policyName = "Behavioral Policy $([guid]::NewGuid().ToString('N'))"

    $ruleResult = New-HashRule -Hash $hash -SourceFileName 'test.exe' -SourceFileLength 1024 -Save -Status 'Approved'
    if ($ruleResult.Success) { $script:ruleId = $ruleResult.Data.Id }

    $policyResult = New-Policy -Name $script:policyName -Phase 1 -EnforcementMode Enabled
    if ($policyResult.Success) { $script:policyId = $policyResult.Data.PolicyId }
}

AfterAll {
    if ($script:policyId) { Remove-Policy -PolicyId $script:policyId -Force | Out-Null }
    if ($script:ruleId) { Remove-RulesBulk -RuleIds @($script:ruleId) | Out-Null }
}

Describe 'Behavioral Policy: create and attach rules' -Tag @('Behavioral','Core') {
    It 'Phase 1 forces AuditOnly enforcement' {
        $policy = Get-Policy -PolicyId $script:policyId
        $policy.Success | Should -BeTrue
        $policy.Data.EnforcementMode | Should -Be 'AuditOnly'
    }

    It 'Add-RuleToPolicy attaches rule id' {
        $addResult = Add-RuleToPolicy -PolicyId $script:policyId -RuleId @($script:ruleId)
        $addResult.Success | Should -BeTrue

        $policy = Get-Policy -PolicyId $script:policyId
        $policy.Success | Should -BeTrue
        $policy.Data.RuleIds | Should -Contain $script:ruleId
    }
}
