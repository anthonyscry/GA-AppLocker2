#Requires -Modules Pester

BeforeAll {
    $ErrorActionPreference = 'Stop'
    $modulePath = Join-Path $PSScriptRoot '..\..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    $script:TestDataRoot = Join-Path $env:TEMP ("GA-AppLocker-E2E-" + [guid]::NewGuid().ToString('N'))

    function global:Get-AppLockerDataPath {
        return $script:TestDataRoot
    }

    function script:Reset-TestDataStore {
        if (Test-Path $script:TestDataRoot) {
            Remove-Item -Path $script:TestDataRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -Path $script:TestDataRoot -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $script:TestDataRoot 'Rules') -ItemType Directory -Force | Out-Null
        Reset-RulesIndexCache
        Rebuild-RulesIndex -RulesPath (Join-Path $script:TestDataRoot 'Rules') | Out-Null
    }

    function script:New-TestHashRule {
        param(
            [string]$Name,
            [string]$Hash,
            [string]$Sid,
            [datetime]$CreatedDate
        )

        return [PSCustomObject]@{
            Id             = [guid]::NewGuid().ToString()
            Name           = $Name
            RuleType       = 'Hash'
            CollectionType = 'Exe'
            Action         = 'Allow'
            Status         = 'Pending'
            Hash           = $Hash
            UserOrGroupSid = $Sid
            CreatedDate    = $CreatedDate.ToString('o')
        }
    }
}

AfterAll {
    if (Test-Path $script:TestDataRoot) {
        Remove-Item -Path $script:TestDataRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Remove-Item -Path Function:\Get-AppLockerDataPath -Force -ErrorAction SilentlyContinue
}

Describe 'Meaningful E2E: critical workflows with edge cases' -Tag @('Behavioral','E2E') {
    BeforeEach {
        Reset-TestDataStore
    }

    It 'Converts mixed artifacts and saves both rule types end-to-end' {
        $artifacts = @(
            [PSCustomObject]@{
                FileName          = 'signed-app.exe'
                FilePath          = 'C:\Program Files\Contoso\signed-app.exe'
                Extension         = '.exe'
                ProductName       = 'Contoso App'
                ProductVersion    = '1.0.0.0'
                Publisher         = 'Contoso Ltd'
                PublisherName     = 'CN=Contoso Ltd'
                SignerCertificate = 'CN=Contoso Ltd'
                IsSigned          = $true
                SHA256Hash        = ('A' * 64)
                SizeBytes         = 12345
                CollectionType    = 'Exe'
            },
            [PSCustomObject]@{
                FileName          = 'unsigned-tool.exe'
                FilePath          = 'C:\Tools\unsigned-tool.exe'
                Extension         = '.exe'
                ProductName       = 'Unsigned Tool'
                ProductVersion    = '2.0.0.0'
                Publisher         = ''
                PublisherName     = ''
                SignerCertificate = ''
                IsSigned          = $false
                SHA256Hash        = ('B' * 64)
                SizeBytes         = 5555
                CollectionType    = 'Exe'
            }
        )

        $convert = ConvertFrom-Artifact -Artifact $artifacts -PreferredRuleType Auto -Save -UserOrGroupSid 'S-1-1-0'

        $convert.Success | Should -BeTrue
        $convert.Data.Count | Should -Be 2

        $types = @($convert.Data | ForEach-Object { $_.RuleType })
        $types | Should -Contain 'Publisher'
        $types | Should -Contain 'Hash'

        $stored = Get-AllRules -Take 100
        $stored.Success | Should -BeTrue
        $stored.Total | Should -Be 2
    }

    It 'Dedupes same-principal duplicates but keeps different principals even with missing index SID' {
        $hash = ('C' * 64)
        $r1 = New-TestHashRule -Name 'Rule-A-Old' -Hash $hash -Sid 'S-1-5-21-111' -CreatedDate (Get-Date).AddMinutes(-10)
        $r2 = New-TestHashRule -Name 'Rule-A-New' -Hash $hash -Sid 'S-1-5-21-111' -CreatedDate (Get-Date)
        $r3 = New-TestHashRule -Name 'Rule-B' -Hash $hash -Sid 'S-1-5-21-222' -CreatedDate (Get-Date).AddMinutes(-5)

        (Add-Rule -Rule $r1).Success | Should -BeTrue
        (Add-Rule -Rule $r2).Success | Should -BeTrue
        (Add-Rule -Rule $r3).Success | Should -BeTrue

        $indexPath = Join-Path $script:TestDataRoot 'rules-index.json'
        $index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json
        foreach ($entry in $index.Rules) {
            if ($entry.Hash -eq $hash) {
                $entry.UserOrGroupSid = $null
            }
        }
        $index | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8
        Reset-RulesIndexCache

        $dedupe = Remove-DuplicateRules -RuleType Hash -Strategy KeepOldest -Force

        $dedupe.Success | Should -BeTrue
        $dedupe.RemovedCount | Should -Be 1

        $remaining = Get-AllRules -Take 100 -FullPayload
        $remaining.Total | Should -Be 2

        $sids = @($remaining.Data | ForEach-Object { $_.UserOrGroupSid } | Sort-Object -Unique)
        $sids.Count | Should -Be 2
        $sids | Should -Contain 'S-1-5-21-111'
        $sids | Should -Contain 'S-1-5-21-222'
    }

    It 'Scans overlapping paths without duplicate artifacts' {
        $scanRoot = Join-Path $script:TestDataRoot 'ScanRoot'
        New-Item -Path $scanRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $scanRoot 'a.ps1') -Value 'Write-Host a' -Encoding UTF8
        Set-Content -Path (Join-Path $scanRoot 'b.ps1') -Value 'Write-Host b' -Encoding UTF8

        $scan = Get-LocalArtifacts -Paths @($scanRoot, $scanRoot) -Extensions @('.ps1') -SkipDllScanning -SkipWshScanning

        $scan.Success | Should -BeTrue
        $scan.Data.Count | Should -Be 2

        $paths = @($scan.Data | ForEach-Object { $_.FilePath })
        (@($paths | Sort-Object -Unique)).Count | Should -Be $paths.Count
    }

    It 'Handles connectivity edge inputs without throwing and returns stable summary' {
        $machines = @(
            $null,
            [PSCustomObject]@{ Hostname = '' },
            [PSCustomObject]@{ Hostname = 'bad&name' },
            [PSCustomObject]@{ Hostname = 'bad&name' }
        )

        $connect = Test-MachineConnectivity -Machines $machines -TestWinRM:$false -TimeoutSeconds 1 -ThrottleLimit 4

        $connect.Success | Should -BeTrue
        $connect.Data.Count | Should -Be 3
        $connect.Summary.TotalMachines | Should -Be 3
        $connect.Data[0].PSObject.Properties.Name | Should -Contain 'IsOnline'
    }
}
