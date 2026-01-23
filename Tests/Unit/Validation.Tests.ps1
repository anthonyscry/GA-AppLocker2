#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Validation Helper functions.

.DESCRIPTION
    Tests all validation and assertion functions.

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Unit\Validation.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}

Describe 'Validation Helpers' -Tag 'Unit', 'Validation' {

    Context 'Test-ValidHash' {

        It 'Returns true for valid SHA256 hash' {
            $validHash = 'A' * 64
            Test-ValidHash -Hash $validHash | Should -BeTrue
        }

        It 'Returns true for lowercase hash' {
            $validHash = 'a' * 64
            Test-ValidHash -Hash $validHash | Should -BeTrue
        }

        It 'Returns true for mixed case hash' {
            $validHash = 'AbCdEf0123456789' * 4
            Test-ValidHash -Hash $validHash | Should -BeTrue
        }

        It 'Returns false for hash with wrong length' {
            Test-ValidHash -Hash ('A' * 63) | Should -BeFalse
            Test-ValidHash -Hash ('A' * 65) | Should -BeFalse
        }

        It 'Returns false for hash with invalid characters' {
            $invalidHash = 'G' * 64  # G is not hex
            Test-ValidHash -Hash $invalidHash | Should -BeFalse
        }

        It 'Returns false for empty or null' {
            Test-ValidHash -Hash '' | Should -BeFalse
            Test-ValidHash -Hash $null | Should -BeFalse
        }
    }

    Context 'Test-ValidSid' {

        It 'Returns true for Everyone SID' {
            Test-ValidSid -Sid 'S-1-1-0' | Should -BeTrue
        }

        It 'Returns true for BUILTIN\Administrators' {
            Test-ValidSid -Sid 'S-1-5-32-544' | Should -BeTrue
        }

        It 'Returns true for domain user SID' {
            Test-ValidSid -Sid 'S-1-5-21-123456789-123456789-123456789-1001' | Should -BeTrue
        }

        It 'Returns false for invalid SID format' {
            Test-ValidSid -Sid 'S-2-1-0' | Should -BeFalse  # Must start with S-1
            Test-ValidSid -Sid 'NotASid' | Should -BeFalse
        }

        It 'Returns false for empty or null' {
            Test-ValidSid -Sid '' | Should -BeFalse
            Test-ValidSid -Sid $null | Should -BeFalse
        }
    }

    Context 'Test-ValidGuid' {

        It 'Returns true for valid GUID with hyphens' {
            Test-ValidGuid -Guid '12345678-1234-1234-1234-123456789abc' | Should -BeTrue
        }

        It 'Returns true for valid GUID without hyphens' {
            Test-ValidGuid -Guid '12345678123412341234123456789abc' | Should -BeTrue
        }

        It 'Returns true for GUID with braces' {
            Test-ValidGuid -Guid '{12345678-1234-1234-1234-123456789abc}' | Should -BeTrue
        }

        It 'Returns false for invalid GUID' {
            Test-ValidGuid -Guid 'not-a-guid' | Should -BeFalse
            Test-ValidGuid -Guid '12345' | Should -BeFalse
        }

        It 'Returns false for empty or null' {
            Test-ValidGuid -Guid '' | Should -BeFalse
            Test-ValidGuid -Guid $null | Should -BeFalse
        }
    }

    Context 'Test-ValidPath' {

        It 'Returns true for valid Windows path' {
            Test-ValidPath -Path 'C:\Program Files\App\app.exe' | Should -BeTrue
        }

        It 'Returns true for UNC path' {
            Test-ValidPath -Path '\\Server\Share\file.txt' | Should -BeTrue
        }

        It 'Returns false for relative path' {
            Test-ValidPath -Path 'relative\path.txt' | Should -BeFalse
        }

        It 'Returns false for path with invalid characters' {
            Test-ValidPath -Path 'C:\Invalid<>Path' | Should -BeFalse
        }

        It 'Returns false for empty or null' {
            Test-ValidPath -Path '' | Should -BeFalse
            Test-ValidPath -Path $null | Should -BeFalse
        }

        It 'MustExist checks path existence' {
            Test-ValidPath -Path 'C:\Windows\System32' -MustExist | Should -BeTrue
            Test-ValidPath -Path 'C:\NonExistent\Path\12345' -MustExist | Should -BeFalse
        }
    }

    Context 'Test-ValidDistinguishedName' {

        It 'Returns true for valid OU DN' {
            Test-ValidDistinguishedName -DistinguishedName 'OU=Computers,DC=corp,DC=local' | Should -BeTrue
        }

        It 'Returns true for CN DN' {
            Test-ValidDistinguishedName -DistinguishedName 'CN=User,OU=Users,DC=domain,DC=com' | Should -BeTrue
        }

        It 'Returns false for invalid DN' {
            Test-ValidDistinguishedName -DistinguishedName 'Invalid DN' | Should -BeFalse
            Test-ValidDistinguishedName -DistinguishedName 'XX=Bad,DC=test' | Should -BeFalse
        }

        It 'Returns false for empty or null' {
            Test-ValidDistinguishedName -DistinguishedName '' | Should -BeFalse
        }
    }

    Context 'Test-ValidHostname' {

        It 'Returns true for valid hostname' {
            Test-ValidHostname -Hostname 'SERVER01' | Should -BeTrue
            Test-ValidHostname -Hostname 'Web-Server-1' | Should -BeTrue
        }

        It 'Returns false for hostname starting with hyphen' {
            Test-ValidHostname -Hostname '-Server' | Should -BeFalse
        }

        It 'Returns false for hostname over 15 characters' {
            Test-ValidHostname -Hostname 'ThisHostnameIsTooLong' | Should -BeFalse
        }

        It 'Returns false for hostname with invalid characters' {
            Test-ValidHostname -Hostname 'Server.Name' | Should -BeFalse
            Test-ValidHostname -Hostname 'Server_Name' | Should -BeFalse
        }
    }

    Context 'Test-ValidCollectionType' {

        It 'Returns true for valid types' {
            Test-ValidCollectionType -CollectionType 'Exe' | Should -BeTrue
            Test-ValidCollectionType -CollectionType 'Dll' | Should -BeTrue
            Test-ValidCollectionType -CollectionType 'Msi' | Should -BeTrue
            Test-ValidCollectionType -CollectionType 'Script' | Should -BeTrue
            Test-ValidCollectionType -CollectionType 'Appx' | Should -BeTrue
        }

        It 'Returns false for invalid type' {
            Test-ValidCollectionType -CollectionType 'Invalid' | Should -BeFalse
            Test-ValidCollectionType -CollectionType 'exe' | Should -BeFalse  # Case sensitive
        }
    }

    Context 'Test-ValidRuleAction' {

        It 'Returns true for Allow and Deny' {
            Test-ValidRuleAction -Action 'Allow' | Should -BeTrue
            Test-ValidRuleAction -Action 'Deny' | Should -BeTrue
        }

        It 'Returns false for invalid action' {
            Test-ValidRuleAction -Action 'Block' | Should -BeFalse
            Test-ValidRuleAction -Action 'allow' | Should -BeFalse
        }
    }

    Context 'Test-ValidRuleStatus' {

        It 'Returns true for valid statuses' {
            Test-ValidRuleStatus -Status 'Pending' | Should -BeTrue
            Test-ValidRuleStatus -Status 'Approved' | Should -BeTrue
            Test-ValidRuleStatus -Status 'Rejected' | Should -BeTrue
            Test-ValidRuleStatus -Status 'Review' | Should -BeTrue
        }

        It 'Returns false for invalid status' {
            Test-ValidRuleStatus -Status 'Active' | Should -BeFalse
        }
    }

    Context 'Test-ValidTier' {

        It 'Returns true for valid tiers 0, 1, 2' {
            Test-ValidTier -Tier 0 | Should -BeTrue
            Test-ValidTier -Tier 1 | Should -BeTrue
            Test-ValidTier -Tier 2 | Should -BeTrue
        }

        It 'Returns false for invalid tier' {
            Test-ValidTier -Tier 3 | Should -BeFalse
            Test-ValidTier -Tier -1 | Should -BeFalse
        }
    }

    Context 'Assert-NotNullOrEmpty' {

        It 'Does not throw for valid value' {
            { Assert-NotNullOrEmpty -Value 'test' -ParameterName 'Param' } | Should -Not -Throw
        }

        It 'Throws for null value' {
            { Assert-NotNullOrEmpty -Value $null -ParameterName 'Param' } | Should -Throw
        }

        It 'Throws for empty string' {
            { Assert-NotNullOrEmpty -Value '' -ParameterName 'Param' } | Should -Throw
        }

        It 'Throws for empty array' {
            { Assert-NotNullOrEmpty -Value @() -ParameterName 'Param' } | Should -Throw
        }

        It 'Uses custom message when provided' {
            { Assert-NotNullOrEmpty -Value $null -ParameterName 'P' -Message 'Custom error' } | 
                Should -Throw -ExpectedMessage 'Custom error'
        }
    }

    Context 'Assert-InRange' {

        It 'Does not throw for value in range' {
            { Assert-InRange -Value 50 -Minimum 0 -Maximum 100 -ParameterName 'P' } | Should -Not -Throw
        }

        It 'Does not throw for value at boundaries' {
            { Assert-InRange -Value 0 -Minimum 0 -Maximum 100 -ParameterName 'P' } | Should -Not -Throw
            { Assert-InRange -Value 100 -Minimum 0 -Maximum 100 -ParameterName 'P' } | Should -Not -Throw
        }

        It 'Throws for value below minimum' {
            { Assert-InRange -Value -1 -Minimum 0 -Maximum 100 -ParameterName 'P' } | Should -Throw
        }

        It 'Throws for value above maximum' {
            { Assert-InRange -Value 101 -Minimum 0 -Maximum 100 -ParameterName 'P' } | Should -Throw
        }
    }

    Context 'Assert-MatchesPattern' {

        It 'Does not throw for matching value' {
            { Assert-MatchesPattern -Value 'ABC123' -Pattern '^[A-Z]+\d+$' -ParameterName 'P' } | Should -Not -Throw
        }

        It 'Throws for non-matching value' {
            { Assert-MatchesPattern -Value 'abc' -Pattern '^\d+$' -ParameterName 'P' } | Should -Throw
        }
    }

    Context 'Assert-InSet' {

        It 'Does not throw for value in set' {
            { Assert-InSet -Value 'A' -AllowedValues @('A', 'B', 'C') -ParameterName 'P' } | Should -Not -Throw
        }

        It 'Throws for value not in set' {
            { Assert-InSet -Value 'D' -AllowedValues @('A', 'B', 'C') -ParameterName 'P' } | Should -Throw
        }
    }

    Context 'ConvertTo-SafeFileName' {

        It 'Replaces invalid characters' {
            $result = ConvertTo-SafeFileName -Value 'File<Name>:Test'
            $result | Should -Not -Match '[<>:]'
        }

        It 'Returns same string if already safe' {
            $result = ConvertTo-SafeFileName -Value 'SafeFileName.txt'
            $result | Should -Be 'SafeFileName.txt'
        }

        It 'Uses custom replacement character' {
            $result = ConvertTo-SafeFileName -Value 'File:Test' -Replacement '-'
            $result | Should -Be 'File-Test'
        }
    }

    Context 'ConvertTo-SafeXmlString' {

        It 'Escapes special XML characters' {
            $result = ConvertTo-SafeXmlString -Value 'Test <value> & "quotes"'
            $result | Should -Match '&lt;'
            $result | Should -Match '&gt;'
            $result | Should -Match '&amp;'
        }

        It 'Returns empty for empty input' {
            $result = ConvertTo-SafeXmlString -Value ''
            $result | Should -Be ''
        }
    }

    Context 'Get-ValidValues' {

        It 'Returns collection types' {
            $values = Get-ValidValues -Type 'CollectionType'
            $values | Should -Contain 'Exe'
            $values | Should -Contain 'Dll'
        }

        It 'Returns rule statuses' {
            $values = Get-ValidValues -Type 'RuleStatus'
            $values | Should -Contain 'Pending'
            $values | Should -Contain 'Approved'
        }
    }
}
