#Requires -Modules Pester

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}

Describe 'Performance budgets' -Tag @('Behavioral','Performance') {
    It 'Get-RuleCounts completes within 5 seconds' {
        $elapsed = (Measure-Command { Get-RuleCounts | Out-Null }).TotalMilliseconds
        $elapsed | Should -BeLessThan 5000
    }

    It 'Get-PolicyCount completes within 2 seconds' {
        $elapsed = (Measure-Command { Get-PolicyCount | Out-Null }).TotalMilliseconds
        $elapsed | Should -BeLessThan 2000
    }
}
