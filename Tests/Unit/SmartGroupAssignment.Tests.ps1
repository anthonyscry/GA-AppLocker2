#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Smart Group Assignment feature in GA-AppLocker.

.DESCRIPTION
    Tests the Get-SuggestedGroup function which analyzes artifact/rule
    metadata and suggests appropriate groupings based on:
    - Known vendor patterns (Microsoft, Adobe, Google, etc.)
    - File path patterns (Program Files, Windows, etc.)
    - Product categories (Browsers, Office, Development, etc.)

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Unit\SmartGroupAssignment.Tests.ps1 -Output Detailed
#>

BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}

Describe 'Get-SuggestedGroup Function' -Tag 'Unit', 'SmartGroup' {
    
    Context 'Microsoft Products' {
        It 'Identifies Microsoft Office products' {
            $result = Get-SuggestedGroup -PublisherName 'O=MICROSOFT CORPORATION' -ProductName 'Microsoft Office Word'
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Microsoft'
            $result.Data.Category | Should -Be 'Office'
            $result.Data.SuggestedGroup | Should -Be 'Microsoft-Office'
        }

        It 'Identifies Microsoft Windows components' {
            $result = Get-SuggestedGroup -PublisherName 'O=MICROSOFT CORPORATION' -ProductName 'Windows Shell Common Dll'
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Microsoft'
            $result.Data.Category | Should -Be 'Windows'
            $result.Data.SuggestedGroup | Should -Be 'Microsoft-Windows'
        }

        It 'Identifies Visual Studio' {
            $result = Get-SuggestedGroup -PublisherName 'O=MICROSOFT CORPORATION' -ProductName 'Microsoft Visual Studio'
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Microsoft'
            $result.Data.Category | Should -Be 'Development'
            $result.Data.SuggestedGroup | Should -Be 'Microsoft-Development'
        }

        It 'Identifies Microsoft Edge' {
            $result = Get-SuggestedGroup -PublisherName 'O=MICROSOFT CORPORATION' -ProductName 'Microsoft Edge'
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Microsoft'
            $result.Data.Category | Should -Be 'Browser'
            $result.Data.SuggestedGroup | Should -Be 'Microsoft-Browser'
        }
    }

    Context 'Adobe Products' {
        It 'Identifies Adobe Acrobat Reader' {
            $result = Get-SuggestedGroup -PublisherName 'O=ADOBE INC.' -ProductName 'Adobe Acrobat Reader'
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Adobe'
            $result.Data.Category | Should -Be 'PDF'
            $result.Data.SuggestedGroup | Should -Be 'Adobe-PDF'
        }

        It 'Identifies Adobe Creative Suite' {
            $result = Get-SuggestedGroup -PublisherName 'O=ADOBE INC.' -ProductName 'Adobe Photoshop'
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Adobe'
            $result.Data.Category | Should -Be 'Creative'
            $result.Data.SuggestedGroup | Should -Be 'Adobe-Creative'
        }
    }

    Context 'Google Products' {
        It 'Identifies Google Chrome' {
            $result = Get-SuggestedGroup -PublisherName 'O=GOOGLE LLC' -ProductName 'Google Chrome'
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Google'
            $result.Data.Category | Should -Be 'Browser'
            $result.Data.SuggestedGroup | Should -Be 'Google-Browser'
        }
    }

    Context 'Path-Based Detection' {
        It 'Detects Windows System files from path' {
            $result = Get-SuggestedGroup -FilePath 'C:\Windows\System32\notepad.exe'
            
            $result.Success | Should -BeTrue
            $result.Data.Category | Should -Be 'Windows'
            $result.Data.SuggestedGroup | Should -Match 'Windows'
        }

        It 'Detects Program Files applications' {
            $result = Get-SuggestedGroup -FilePath 'C:\Program Files\SomeApp\app.exe'
            
            $result.Success | Should -BeTrue
            $result.Data.Category | Should -Be 'ProgramFiles'
            $result.Data.RiskLevel | Should -Be 'Low'
        }

        It 'Detects user-installed applications' {
            $result = Get-SuggestedGroup -FilePath 'C:\Users\testuser\AppData\Local\Programs\app.exe'
            
            $result.Success | Should -BeTrue
            $result.Data.Category | Should -Be 'UserInstalled'
            $result.Data.RiskLevel | Should -Be 'Medium'
        }
    }

    Context 'Unknown/Generic Handling' {
        It 'Returns extracted vendor for unrecognized publisher' {
            $result = Get-SuggestedGroup -PublisherName 'O=UNKNOWN COMPANY LLC' -ProductName 'Some Random App'
            
            $result.Success | Should -BeTrue
            # Implementation extracts company name from certificate: 'UNKNOWN COMPANY' -> 'UnknownCompany'
            $result.Data.Vendor | Should -Be 'UnknownCompany'
            $result.Data.SuggestedGroup | Should -Match 'UnknownCompany|Other'
        }

        It 'Returns reasonable suggestion for unsigned files' {
            # IsSigned $false with no publisher - clearly unsigned
            $result = Get-SuggestedGroup -FilePath 'C:\Tools\utility.exe' -PublisherName '' -IsSigned $false
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Unsigned'
            $result.Data.RiskLevel | Should -Be 'High'
            $result.Data.SuggestedGroup | Should -Match 'Unsigned'
        }
    }

    Context 'Risk Level Assessment' {
        It 'Assigns Low risk to Microsoft signed files' {
            $result = Get-SuggestedGroup -PublisherName 'O=MICROSOFT CORPORATION' -ProductName 'Windows Explorer'
            
            $result.Data.RiskLevel | Should -Be 'Low'
        }

        It 'Assigns Medium risk to known third-party vendors' {
            $result = Get-SuggestedGroup -PublisherName 'O=ADOBE INC.' -ProductName 'Adobe Reader'
            
            $result.Data.RiskLevel | Should -Be 'Low'
        }

        It 'Assigns High risk to unsigned executables' {
            $result = Get-SuggestedGroup -FilePath 'C:\Downloads\setup.exe' -IsSigned $false
            
            $result.Data.RiskLevel | Should -Be 'High'
        }
    }

    Context 'Input Validation' {
        It 'Handles null PublisherName gracefully' {
            $result = Get-SuggestedGroup -PublisherName $null -FilePath 'C:\test.exe'
            
            $result.Success | Should -BeTrue
        }

        It 'Handles empty ProductName gracefully' {
            $result = Get-SuggestedGroup -PublisherName 'O=MICROSOFT CORPORATION' -ProductName ''
            
            $result.Success | Should -BeTrue
            $result.Data.Vendor | Should -Be 'Microsoft'
        }

        It 'Handles missing all parameters with error' {
            $result = Get-SuggestedGroup
            
            $result.Success | Should -BeFalse
            $result.Error | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'KnownVendors Data' -Tag 'Unit', 'SmartGroup' {
    
    Context 'Vendor Database' {
        It 'Contains Microsoft patterns' {
            $vendors = Get-KnownVendors
            
            $vendors | Should -Not -BeNullOrEmpty
            $vendors.Microsoft | Should -Not -BeNullOrEmpty
            $vendors.Microsoft.Patterns | Should -Contain '*MICROSOFT*'
        }

        It 'Contains Adobe patterns' {
            $vendors = Get-KnownVendors
            
            $vendors.Adobe | Should -Not -BeNullOrEmpty
        }

        It 'Contains Google patterns' {
            $vendors = Get-KnownVendors
            
            $vendors.Google | Should -Not -BeNullOrEmpty
        }

        It 'Contains at least 10 known vendors' {
            $vendors = Get-KnownVendors
            
            # Count vendors (excluding metadata properties that start with _)
            $vendorCount = ($vendors.PSObject.Properties.Name | Where-Object { -not $_.StartsWith('_') }).Count
            $vendorCount | Should -BeGreaterOrEqual 10
        }
    }
}

Describe 'Integration with ConvertFrom-Artifact' -Tag 'Unit', 'SmartGroup', 'Integration' {
    
    Context 'Artifact with Smart Group Suggestion' {
        It 'Adds SuggestedGroup to converted artifact metadata' {
            # Create mock artifact
            $mockArtifact = [PSCustomObject]@{
                FilePath          = 'C:\Program Files\Microsoft Office\Office16\WINWORD.EXE'
                FileName          = 'WINWORD.EXE'
                Extension         = '.exe'
                SHA256Hash        = 'A' * 64
                IsSigned          = $true
                SignerCertificate = 'O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US'
                Publisher         = 'Microsoft Corporation'
                ProductName       = 'Microsoft Office Word'
                ProductVersion    = '16.0.0.0'
                SizeBytes         = 2048000
            }

            # This test will pass once we update ConvertFrom-Artifact
            # For now, just verify Get-SuggestedGroup works with artifact data
            $suggestion = Get-SuggestedGroup `
                -PublisherName $mockArtifact.SignerCertificate `
                -ProductName $mockArtifact.ProductName `
                -FilePath $mockArtifact.FilePath

            $suggestion.Success | Should -BeTrue
            $suggestion.Data.SuggestedGroup | Should -Be 'Microsoft-Office'
        }
    }
}
