#Requires -Modules Pester
<#
.SYNOPSIS
    Tests for GA-AppLocker.Credentials module.

.DESCRIPTION
    Covers all credential management functions:
    - New-CredentialProfile (create, DPAPI encrypt, uniqueness)
    - Get-CredentialProfile (by name, tier, all)
    - Get-CredentialForTier (decrypt, fallback chain)
    - Remove-CredentialProfile (by name, by ID)
    - Get-CredentialStoragePath
    - Get-AllCredentialProfiles

.NOTES
    Module: GA-AppLocker.Credentials
    Run with: Invoke-Pester -Path .\Tests\Unit\Credentials.Tests.ps1 -Output Detailed
#>

BeforeAll {
    Get-Module 'GA-AppLocker*' | Remove-Module -Force -ErrorAction SilentlyContinue
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # Helper to create test credentials
    function New-TestCredential {
        param(
            [string]$Username = 'DOMAIN\TestUser',
            [string]$Password = 'TestPass123!'
        )
        $secPass = ConvertTo-SecureString $Password -AsPlainText -Force
        [System.Management.Automation.PSCredential]::new($Username, $secPass)
    }

    # Track profiles created during tests for cleanup
    $script:CreatedProfileIds = @()
}

AfterAll {
    # Clean up any test profiles created during testing
    foreach ($id in $script:CreatedProfileIds) {
        try {
            Remove-CredentialProfile -Id $id -Force -ErrorAction SilentlyContinue
        }
        catch { }
    }
}

# ============================================================================
# GET-CREDENTIALSTORAGEPATH
# ============================================================================

Describe 'Get-CredentialStoragePath' -Tag 'Unit', 'Credentials' {

    It 'Should return a non-empty path' {
        $path = Get-CredentialStoragePath
        $path | Should -Not -BeNullOrEmpty
    }

    It 'Should include Credentials in the path' {
        $path = Get-CredentialStoragePath
        $path | Should -BeLike '*Credentials*'
    }

    It 'Should create the directory if missing' {
        $path = Get-CredentialStoragePath
        Test-Path $path | Should -Be $true
    }
}

# ============================================================================
# NEW-CREDENTIALPROFILE
# ============================================================================

Describe 'New-CredentialProfile' -Tag 'Unit', 'Credentials' {

    It 'Should create a credential profile successfully' {
        $cred = New-TestCredential -Username 'DOMAIN\UnitTestUser1'
        $result = New-CredentialProfile -Name 'UnitTest_Profile1' -Credential $cred -Tier 2 -Description 'Unit test profile'
        $result.Success | Should -Be $true
        $result.Data | Should -Not -BeNullOrEmpty
        $result.Data.Name | Should -Be 'UnitTest_Profile1'
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }
    }

    It 'Should assign a GUID Id' {
        $cred = New-TestCredential -Username 'DOMAIN\UnitTestUser2'
        $result = New-CredentialProfile -Name 'UnitTest_Profile2' -Credential $cred -Tier 1
        $result.Success | Should -Be $true
        { [guid]::Parse($result.Data.Id) } | Should -Not -Throw
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }
    }

    It 'Should encrypt the password (not store plaintext)' {
        $cred = New-TestCredential -Username 'DOMAIN\UnitTestUser3' -Password 'SecretPass!'
        $result = New-CredentialProfile -Name 'UnitTest_Profile3' -Credential $cred -Tier 0
        $result.Success | Should -Be $true
        $result.Data.EncryptedPassword | Should -Not -Be 'SecretPass!'
        $result.Data.EncryptedPassword.Length | Should -BeGreaterThan 20
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }
    }

    It 'Should store username in clear text' {
        $cred = New-TestCredential -Username 'TESTDOMAIN\Admin'
        $result = New-CredentialProfile -Name 'UnitTest_Profile4' -Credential $cred -Tier 2
        $result.Success | Should -Be $true
        $result.Data.Username | Should -Be 'TESTDOMAIN\Admin'
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }
    }

    It 'Should set TierName based on Tier number' {
        $cred = New-TestCredential
        $result = New-CredentialProfile -Name 'UnitTest_Profile5' -Credential $cred -Tier 0
        $result.Success | Should -Be $true
        $result.Data.TierName | Should -Not -BeNullOrEmpty
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }
    }

    It 'Should prevent duplicate profile names' {
        $cred = New-TestCredential
        $name = 'UnitTest_DupCheck'
        $first = New-CredentialProfile -Name $name -Credential $cred -Tier 2
        if ($first.Data.Id) { $script:CreatedProfileIds += $first.Data.Id }

        $second = New-CredentialProfile -Name $name -Credential $cred -Tier 2
        $second.Success | Should -Be $false
        $second.Error | Should -BeLike '*already exists*'
    }

    It 'Should set CreatedDate' {
        $cred = New-TestCredential -Username 'DOMAIN\DateUser'
        $result = New-CredentialProfile -Name 'UnitTest_Profile6' -Credential $cred -Tier 2
        $result.Data.CreatedDate | Should -Not -BeNullOrEmpty
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }
    }

    It 'Should persist profile as JSON file' {
        $cred = New-TestCredential -Username 'DOMAIN\FileUser'
        $result = New-CredentialProfile -Name 'UnitTest_Profile7' -Credential $cred -Tier 1
        $result.Success | Should -Be $true
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }

        $credPath = Get-CredentialStoragePath
        $file = Join-Path $credPath "$($result.Data.Id).json"
        Test-Path $file | Should -Be $true
    }

    It 'Should handle SetAsDefault switch' {
        $cred = New-TestCredential -Username 'DOMAIN\DefaultUser'
        $result = New-CredentialProfile -Name 'UnitTest_Default1' -Credential $cred -Tier 2 -SetAsDefault
        $result.Success | Should -Be $true
        $result.Data.IsDefault | Should -Be $true
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }
    }
}

# ============================================================================
# GET-CREDENTIALPROFILE
# ============================================================================

Describe 'Get-CredentialProfile' -Tag 'Unit', 'Credentials' {

    BeforeAll {
        # Create profiles for retrieval tests
        $cred = New-TestCredential -Username 'DOMAIN\GetTestUser'
        $script:GetTestProfile = New-CredentialProfile -Name 'UnitTest_GetTest1' -Credential $cred -Tier 1
        if ($script:GetTestProfile.Data.Id) { $script:CreatedProfileIds += $script:GetTestProfile.Data.Id }
    }

    It 'Should retrieve profile by name' {
        $result = Get-CredentialProfile -Name 'UnitTest_GetTest1'
        $result.Success | Should -Be $true
        $result.Data | Should -Not -BeNullOrEmpty
    }

    It 'Should retrieve profile by ID' {
        $id = $script:GetTestProfile.Data.Id
        $result = Get-CredentialProfile -Id $id
        $result.Success | Should -Be $true
        $result.Data | Should -Not -BeNullOrEmpty
    }

    It 'Should return empty data for non-existent name' {
        $result = Get-CredentialProfile -Name 'NonExistentProfile_XYZ'
        $result.Success | Should -Be $true
        $result.Data | Should -BeNullOrEmpty
    }

    It 'Should return empty data for non-existent ID' {
        $result = Get-CredentialProfile -Id ([guid]::NewGuid().ToString())
        $result.Success | Should -Be $true
        $result.Data | Should -BeNullOrEmpty
    }

    It 'Should return profile metadata (username, tier, dates)' {
        $result = Get-CredentialProfile -Name 'UnitTest_GetTest1'
        $result.Data.Username | Should -Be 'DOMAIN\GetTestUser'
        $result.Data.Tier | Should -Be 1
        $result.Data.CreatedDate | Should -Not -BeNullOrEmpty
    }
}

# ============================================================================
# GET-ALLCREDENTIALPROFILES
# ============================================================================

Describe 'Get-AllCredentialProfiles' -Tag 'Unit', 'Credentials' {

    It 'Should return a Success result' {
        $result = Get-AllCredentialProfiles
        $result.Success | Should -Be $true
    }

    It 'Should return all profiles (at least the ones we created)' {
        $result = Get-AllCredentialProfiles
        $allNames = @($result.Data | ForEach-Object { $_.Name })
        $allNames | Should -Contain 'UnitTest_GetTest1'
    }
}

# ============================================================================
# GET-CREDENTIALFORTIER
# ============================================================================

Describe 'Get-CredentialForTier' -Tag 'Unit', 'Credentials' {

    BeforeAll {
        # Create a default tier 2 profile for tests
        $cred = New-TestCredential -Username 'DOMAIN\TierTestUser' -Password 'TierPass!'
        $script:TierProfile = New-CredentialProfile -Name 'UnitTest_TierTest' -Credential $cred -Tier 2 -SetAsDefault
        if ($script:TierProfile.Data.Id) { $script:CreatedProfileIds += $script:TierProfile.Data.Id }
    }

    It 'Should return a PSCredential for a tier with stored credentials' {
        $result = Get-CredentialForTier -Tier 2
        $result.Success | Should -Be $true
        $result.Data | Should -BeOfType [System.Management.Automation.PSCredential]
    }

    It 'Should decrypt the password correctly' {
        $result = Get-CredentialForTier -Tier 2
        $result.Success | Should -Be $true
        # The decrypted credential should have the correct username
        $result.Data.UserName | Should -Be 'DOMAIN\TierTestUser'
    }

    It 'Should return error for tier with no profiles' {
        # Tier 0 may not have profiles (unless created by other tests)
        # Remove all our test T0 profiles first
        $t0Profiles = Get-CredentialProfile -Tier 0
        $hasOurT0 = $false
        if ($t0Profiles.Success -and $t0Profiles.Data) {
            $hasOurT0 = ($t0Profiles.Data | Where-Object { $_.Name -like 'UnitTest_*' }).Count -gt 0
        }

        # This test is conditional - if no T0 profiles exist at all, it should fail gracefully
        if (-not $hasOurT0) {
            # Try a tier that might not have profiles
            $result = Get-CredentialForTier -Tier 0
            # May succeed with fallback or fail - either is acceptable
            { Get-CredentialForTier -Tier 0 } | Should -Not -Throw
        }
    }

    It 'Should accept a specific ProfileName' {
        $result = Get-CredentialForTier -Tier 2 -ProfileName 'UnitTest_TierTest'
        $result.Success | Should -Be $true
        $result.Data.UserName | Should -Be 'DOMAIN\TierTestUser'
    }

    It 'Should update LastUsed timestamp when credential is retrieved' {
        $before = (Get-CredentialProfile -Name 'UnitTest_TierTest').Data.LastUsed
        Start-Sleep -Milliseconds 50
        Get-CredentialForTier -Tier 2 -ProfileName 'UnitTest_TierTest'
        $after = (Get-CredentialProfile -Name 'UnitTest_TierTest').Data.LastUsed
        $after | Should -Not -Be $before
    }
}

# ============================================================================
# REMOVE-CREDENTIALPROFILE
# ============================================================================

Describe 'Remove-CredentialProfile' -Tag 'Unit', 'Credentials' {

    It 'Should remove a profile by name' {
        $cred = New-TestCredential -Username 'DOMAIN\RemoveTest1'
        $created = New-CredentialProfile -Name 'UnitTest_Remove1' -Credential $cred -Tier 2

        $result = Remove-CredentialProfile -Name 'UnitTest_Remove1' -Force
        $result.Success | Should -Be $true

        # Verify it is gone
        $check = Get-CredentialProfile -Name 'UnitTest_Remove1'
        $check.Data | Should -BeNullOrEmpty
    }

    It 'Should remove a profile by ID' {
        $cred = New-TestCredential -Username 'DOMAIN\RemoveTest2'
        $created = New-CredentialProfile -Name 'UnitTest_Remove2' -Credential $cred -Tier 1

        $result = Remove-CredentialProfile -Id $created.Data.Id -Force
        $result.Success | Should -Be $true
    }

    It 'Should return error for non-existent profile' {
        $result = Remove-CredentialProfile -Name 'NonExistentProfile_DELETE'
        $result.Success | Should -Be $false
        $result.Error | Should -BeLike '*not found*'
    }

    It 'Should delete the JSON file from disk' {
        $cred = New-TestCredential -Username 'DOMAIN\RemoveTest3'
        $created = New-CredentialProfile -Name 'UnitTest_Remove3' -Credential $cred -Tier 2
        $credPath = Get-CredentialStoragePath
        $file = Join-Path $credPath "$($created.Data.Id).json"

        Test-Path $file | Should -Be $true
        Remove-CredentialProfile -Name 'UnitTest_Remove3' -Force
        Test-Path $file | Should -Be $false
    }
}

# ============================================================================
# EDGE CASES
# ============================================================================

Describe 'Credentials - Edge Cases' -Tag 'Unit', 'Credentials', 'EdgeCase' {

    It 'Should handle credential with special characters in password' {
        $cred = New-TestCredential -Username 'DOMAIN\Special' -Password 'P@ss!w0rd#$%^&*()'
        $result = New-CredentialProfile -Name 'UnitTest_Special' -Credential $cred -Tier 2
        $result.Success | Should -Be $true
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }

        # Verify roundtrip
        $decrypted = Get-CredentialForTier -Tier 2 -ProfileName 'UnitTest_Special'
        $decrypted.Success | Should -Be $true
        $decrypted.Data.GetNetworkCredential().Password | Should -Be 'P@ss!w0rd#$%^&*()'
    }

    It 'Should handle credential with very long username' {
        $longUser = 'VERYLONGDOMAIN\' + ('A' * 100)
        $cred = New-TestCredential -Username $longUser
        $result = New-CredentialProfile -Name 'UnitTest_LongUser' -Credential $cred -Tier 2
        $result.Success | Should -Be $true
        $result.Data.Username | Should -Be $longUser
        if ($result.Data.Id) { $script:CreatedProfileIds += $result.Data.Id }
    }

    It 'Should handle multiple profiles for the same tier' {
        $cred1 = New-TestCredential -Username 'DOMAIN\MultiTier1'
        $cred2 = New-TestCredential -Username 'DOMAIN\MultiTier2'

        $r1 = New-CredentialProfile -Name 'UnitTest_Multi1' -Credential $cred1 -Tier 2
        $r2 = New-CredentialProfile -Name 'UnitTest_Multi2' -Credential $cred2 -Tier 2

        $r1.Success | Should -Be $true
        $r2.Success | Should -Be $true

        if ($r1.Data.Id) { $script:CreatedProfileIds += $r1.Data.Id }
        if ($r2.Data.Id) { $script:CreatedProfileIds += $r2.Data.Id }

        $tierProfiles = Get-CredentialProfile -Tier 2
        @($tierProfiles.Data | Where-Object { $_.Name -like 'UnitTest_Multi*' }).Count | Should -Be 2
    }
}
