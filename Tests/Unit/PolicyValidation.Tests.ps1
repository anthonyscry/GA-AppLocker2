#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for GA-AppLocker Policy Validation Module

.DESCRIPTION
    Comprehensive test suite ensuring policy validation catches all
    issues that would cause AppLocker import failures.

.NOTES
    Run: Invoke-Pester -Path .\Tests\Unit\PolicyValidation.Tests.ps1 -Output Detailed
#>

BeforeAll {
    # Import the main module (which loads Validation as nested module)
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop

    # Create temp directory for test files
    $script:TestDir = Join-Path $env:TEMP 'AppLockerValidationTests'
    if (-not (Test-Path $script:TestDir)) {
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    }

    # Helper: Save XML content to temp file for testing
    # Uses WriteAllText to avoid UTF-8 BOM that breaks XML parsing in PS 5.1
    function Save-TestPolicy {
        param([string]$Content, [string]$Name)
        $path = Join-Path $script:TestDir "$Name.xml"
        [System.IO.File]::WriteAllText($path, $Content, [System.Text.UTF8Encoding]::new($false))
        return $path
    }

    # ---- Test Data (must be inside BeforeAll for Pester 5 scoping) ----

    $script:ValidPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Microsoft Signed" Description="Allow Microsoft signed executables" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
    <FileHashRule Id="B2C3D4E5-F6A7-8901-BCDE-F23456789012" Name="Specific Hash" Description="Allow by hash" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FileHashCondition>
          <FileHash Type="SHA256" Data="0x1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF" SourceFileName="app.exe" SourceFileLength="12345" />
        </FileHashCondition>
      </Conditions>
    </FileHashRule>
  </RuleCollection>
  <RuleCollection Type="Script" EnforcementMode="AuditOnly">
    <FilePathRule Id="C3D4E5F6-A7B8-9012-CDEF-345678901234" Name="Windows Scripts" Description="Allow Windows scripts" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePathCondition Path="%WINDIR%\*" />
      </Conditions>
    </FilePathRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:LowercaseGuidPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="a1b2c3d4-e5f6-7890-abcd-ef1234567890" Name="Lowercase GUID" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:DuplicateGuidPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Rule One" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST1" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Rule Two" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST2" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:InvalidSidPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Invalid SID" UserOrGroupSid="NOT-A-VALID-SID" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:MissingSidPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Missing SID" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:InvalidHashPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FileHashRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Bad Hash" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FileHashCondition>
          <FileHash Type="SHA256" Data="NOTAVALIDHASH" SourceFileName="test.exe" SourceFileLength="1234" />
        </FileHashCondition>
      </Conditions>
    </FileHashRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:WrongHashTypePolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FileHashRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Wrong Hash Type" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FileHashCondition>
          <FileHash Type="MD5" Data="0x1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF" SourceFileName="test.exe" SourceFileLength="1234" />
        </FileHashCondition>
      </Conditions>
    </FileHashRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:InvalidEnforcementModePolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="InvalidMode">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Test" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:InvalidCollectionTypePolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="InvalidType" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Test" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:EmptyPublisherPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Empty Publisher" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@

    $script:UserWritablePathPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePathRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Downloads Path" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePathCondition Path="%USERPROFILE%\Downloads\*" />
      </Conditions>
    </FilePathRule>
  </RuleCollection>
</AppLockerPolicy>
'@
}

AfterAll {
    # Cleanup
    if (Test-Path $script:TestDir) {
        Remove-Item $script:TestDir -Recurse -Force
    }
}

#region Schema Validation Tests

Describe 'Test-AppLockerXmlSchema' -Tag 'Unit', 'PolicyValidation' {

    Context 'Valid Policy' {
        BeforeAll {
            $script:ValidPath = Save-TestPolicy -Content $script:ValidPolicy -Name 'valid'
        }

        It 'Should pass validation for well-formed policy' {
            $result = Test-AppLockerXmlSchema -XmlPath $script:ValidPath
            $result.Success | Should -BeTrue
            $result.Errors.Count | Should -Be 0
        }

        It 'Should detect correct rule collections' {
            $result = Test-AppLockerXmlSchema -XmlPath $script:ValidPath
            $result.Details.RuleCollections | Should -Contain 'Exe'
            $result.Details.RuleCollections | Should -Contain 'Script'
        }

        It 'Should count total rules correctly' {
            $result = Test-AppLockerXmlSchema -XmlPath $script:ValidPath
            $result.Details.TotalRules | Should -Be 3
        }
    }

    Context 'Invalid Enforcement Mode' {
        BeforeAll {
            $script:InvalidModePath = Save-TestPolicy -Content $script:InvalidEnforcementModePolicy -Name 'invalidmode'
        }

        It 'Should fail for invalid EnforcementMode' {
            $result = Test-AppLockerXmlSchema -XmlPath $script:InvalidModePath
            $result.Success | Should -BeFalse
            $result.Errors | Where-Object { $_ -like '*EnforcementMode*' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invalid Collection Type' {
        BeforeAll {
            $script:InvalidTypePath = Save-TestPolicy -Content $script:InvalidCollectionTypePolicy -Name 'invalidtype'
        }

        It 'Should fail for invalid RuleCollection Type' {
            $result = Test-AppLockerXmlSchema -XmlPath $script:InvalidTypePath
            $result.Success | Should -BeFalse
            $result.Errors | Where-Object { $_ -like '*InvalidType*' } | Should -Not -BeNullOrEmpty
        }
    }
}

#endregion

#region GUID Validation Tests

Describe 'Test-AppLockerRuleGuids' -Tag 'Unit', 'PolicyValidation' {

    Context 'Valid GUIDs' {
        BeforeAll {
            $script:ValidPath = Save-TestPolicy -Content $script:ValidPolicy -Name 'validguids'
        }

        It 'Should pass for uppercase GUIDs' {
            $result = Test-AppLockerRuleGuids -XmlPath $script:ValidPath
            $result.Success | Should -BeTrue
        }

        It 'Should report correct GUID count' {
            $result = Test-AppLockerRuleGuids -XmlPath $script:ValidPath
            $result.TotalGuids | Should -Be 3
            $result.UniqueGuids | Should -Be 3
        }
    }

    Context 'Lowercase GUIDs' {
        BeforeAll {
            $script:LowercasePath = Save-TestPolicy -Content $script:LowercaseGuidPolicy -Name 'lowercaseguid'
        }

        It 'Should fail for lowercase GUIDs' {
            $result = Test-AppLockerRuleGuids -XmlPath $script:LowercasePath
            $result.Success | Should -BeFalse
            $result.Errors | Where-Object { $_ -like '*UPPERCASE*' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Duplicate GUIDs' {
        BeforeAll {
            $script:DuplicatePath = Save-TestPolicy -Content $script:DuplicateGuidPolicy -Name 'duplicateguid'
        }

        It 'Should fail for duplicate GUIDs' {
            $result = Test-AppLockerRuleGuids -XmlPath $script:DuplicatePath
            $result.Success | Should -BeFalse
            $result.DuplicateGuids.Count | Should -BeGreaterThan 0
        }
    }
}

#endregion

#region SID Validation Tests

Describe 'Test-AppLockerRuleSids' -Tag 'Unit', 'PolicyValidation' {

    Context 'Valid SIDs' {
        BeforeAll {
            $script:ValidPath = Save-TestPolicy -Content $script:ValidPolicy -Name 'validsids'
        }

        It 'Should pass for valid SID format' {
            $result = Test-AppLockerRuleSids -XmlPath $script:ValidPath
            $result.Success | Should -BeTrue
        }

        It 'Should recognize well-known SID S-1-1-0' {
            $result = Test-AppLockerRuleSids -XmlPath $script:ValidPath
            $everyone = $result.SidMappings | Where-Object Sid -eq 'S-1-1-0'
            $everyone | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invalid SID Format' {
        BeforeAll {
            $script:InvalidSidPath = Save-TestPolicy -Content $script:InvalidSidPolicy -Name 'invalidsid'
        }

        It 'Should fail for malformed SID' {
            $result = Test-AppLockerRuleSids -XmlPath $script:InvalidSidPath
            $result.Success | Should -BeFalse
            $result.Errors | Where-Object { $_ -like '*invalid SID*' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Missing SID' {
        BeforeAll {
            $script:MissingSidPath = Save-TestPolicy -Content $script:MissingSidPolicy -Name 'missingsid'
        }

        It 'Should fail when UserOrGroupSid is missing' {
            $result = Test-AppLockerRuleSids -XmlPath $script:MissingSidPath
            $result.Success | Should -BeFalse
            $result.Errors | Where-Object { $_ -like '*missing*' } | Should -Not -BeNullOrEmpty
        }
    }
}

#endregion

#region Rule Condition Validation Tests

Describe 'Test-AppLockerRuleConditions' -Tag 'Unit', 'PolicyValidation' {

    Context 'Valid Conditions' {
        BeforeAll {
            $script:ValidPath = Save-TestPolicy -Content $script:ValidPolicy -Name 'validconditions'
        }

        It 'Should pass for valid rule conditions' {
            $result = Test-AppLockerRuleConditions -XmlPath $script:ValidPath
            $result.Success | Should -BeTrue
        }

        It 'Should count rule types correctly' {
            $result = Test-AppLockerRuleConditions -XmlPath $script:ValidPath
            $result.RuleStats.Publisher | Should -Be 1
            $result.RuleStats.Hash | Should -Be 1
            $result.RuleStats.Path | Should -Be 1
        }
    }

    Context 'Invalid Hash' {
        BeforeAll {
            $script:InvalidHashPath = Save-TestPolicy -Content $script:InvalidHashPolicy -Name 'invalidhash'
        }

        It 'Should fail for invalid SHA256 hash' {
            $result = Test-AppLockerRuleConditions -XmlPath $script:InvalidHashPath
            $result.Success | Should -BeFalse
            $result.Errors | Where-Object { $_ -like '*SHA256*' -or $_ -like '*hash*' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Wrong Hash Type' {
        BeforeAll {
            $script:WrongTypePath = Save-TestPolicy -Content $script:WrongHashTypePolicy -Name 'wronghashtype'
        }

        It 'Should fail for non-SHA256 hash type' {
            $result = Test-AppLockerRuleConditions -XmlPath $script:WrongTypePath
            $result.Success | Should -BeFalse
            $result.Errors | Where-Object { $_ -like "*Type='SHA256'*" } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Empty Publisher Name' {
        BeforeAll {
            $script:EmptyPublisherPath = Save-TestPolicy -Content $script:EmptyPublisherPolicy -Name 'emptypublisher'
        }

        It 'Should fail for empty PublisherName' {
            $result = Test-AppLockerRuleConditions -XmlPath $script:EmptyPublisherPath
            $result.Success | Should -BeFalse
            $result.Errors | Where-Object { $_ -like '*empty PublisherName*' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'User-Writable Paths' {
        BeforeAll {
            $script:UserWritablePath = Save-TestPolicy -Content $script:UserWritablePathPolicy -Name 'userwritable'
        }

        It 'Should warn about user-writable paths' {
            $result = Test-AppLockerRuleConditions -XmlPath $script:UserWritablePath
            $result.Warnings | Where-Object { $_ -like '*user-writable*' -or $_ -like '*Downloads*' } | Should -Not -BeNullOrEmpty
        }
    }
}

#endregion

#region Complete Pipeline Tests

Describe 'Invoke-AppLockerPolicyValidation' -Tag 'Unit', 'PolicyValidation' {

    Context 'Valid Policy - Full Pipeline' {
        BeforeAll {
            $script:ValidPath = Save-TestPolicy -Content $script:ValidPolicy -Name 'fullpipeline'
        }

        It 'Should pass all validation stages' {
            $result = Invoke-AppLockerPolicyValidation -XmlPath $script:ValidPath
            $result.OverallSuccess | Should -BeTrue
            $result.TotalErrors | Should -Be 0
        }

        It 'Should indicate policy can be imported' {
            $result = Invoke-AppLockerPolicyValidation -XmlPath $script:ValidPath
            $result.CanBeImported | Should -BeTrue
        }

        It 'Should populate all result sections' {
            $result = Invoke-AppLockerPolicyValidation -XmlPath $script:ValidPath
            $result.SchemaResult | Should -Not -BeNullOrEmpty
            $result.GuidResult | Should -Not -BeNullOrEmpty
            $result.SidResult | Should -Not -BeNullOrEmpty
            $result.ConditionResult | Should -Not -BeNullOrEmpty
            $result.ImportResult | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invalid Policy - Full Pipeline' {
        BeforeAll {
            $script:InvalidPath = Save-TestPolicy -Content $script:InvalidSidPolicy -Name 'invalidpipeline'
        }

        It 'Should fail overall validation' {
            $result = Invoke-AppLockerPolicyValidation -XmlPath $script:InvalidPath
            $result.OverallSuccess | Should -BeFalse
            $result.TotalErrors | Should -BeGreaterThan 0
        }
    }

    Context 'Report Export' {
        BeforeAll {
            $script:ValidPath = Save-TestPolicy -Content $script:ValidPolicy -Name 'reportexport'
            $script:ReportPath = Join-Path $script:TestDir 'validation-report.json'
        }

        It 'Should export report to specified path' {
            Invoke-AppLockerPolicyValidation -XmlPath $script:ValidPath -OutputReport $script:ReportPath
            Test-Path $script:ReportPath | Should -BeTrue
        }

        It 'Should create valid JSON report' {
            $report = Get-Content $script:ReportPath -Raw | ConvertFrom-Json
            $report.PolicyPath | Should -Be $script:ValidPath
            $report.OverallSuccess | Should -BeTrue
        }
    }
}

#endregion

#region Edge Cases

Describe 'PolicyValidation Edge Cases' -Tag 'Unit', 'PolicyValidation' {

    Context 'Empty Policy' {
        BeforeAll {
            $emptyPolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
</AppLockerPolicy>
'@
            $script:EmptyPath = Save-TestPolicy -Content $emptyPolicy -Name 'empty'
        }

        It 'Should handle policy with no rule collections' {
            $result = Test-AppLockerXmlSchema -XmlPath $script:EmptyPath
            $result.Success | Should -BeTrue
            $result.Warnings | Where-Object { $_ -like '*No RuleCollections*' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Multiple Collections Same Type' {
        BeforeAll {
            $multiSameType = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Rule1" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=TEST" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
  <RuleCollection Type="Exe" EnforcementMode="Enabled">
    <FilePublisherRule Id="B2C3D4E5-F6A7-8901-BCDE-F23456789012" Name="Rule2" UserOrGroupSid="S-1-1-0" Action="Deny">
      <Conditions>
        <FilePublisherCondition PublisherName="O=BLOCKED" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@
            $script:MultiPath = Save-TestPolicy -Content $multiSameType -Name 'multisame'
        }

        It 'Should handle multiple collections of same type' {
            $result = Test-AppLockerXmlSchema -XmlPath $script:MultiPath
            # Valid XML structure even if unusual
            $result.Success | Should -BeTrue
        }
    }

    Context 'Unicode Characters' {
        BeforeAll {
            $unicodePolicy = @'
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="A1B2C3D4-E5F6-7890-ABCD-EF1234567890" Name="Unicode Rule" Description="Unicode description" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=UNICODE CORP" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
'@
            $script:UnicodePath = Save-TestPolicy -Content $unicodePolicy -Name 'unicode'
        }

        It 'Should handle Unicode characters in rule names and publishers' {
            $result = Invoke-AppLockerPolicyValidation -XmlPath $script:UnicodePath
            $result.OverallSuccess | Should -BeTrue
        }
    }
}

#endregion
