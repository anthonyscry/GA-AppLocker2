<#
.SYNOPSIS
    Suggests a group name for an artifact or rule based on vendor and product patterns.

.DESCRIPTION
    Analyzes publisher certificate, product name, and file path to suggest
    an appropriate grouping for AppLocker rules. Uses a database of known
    vendors and product categories to provide intelligent suggestions.

    This enables:
    - Automatic rule organization by vendor/category
    - Risk-based categorization (Low/Medium/High)
    - Consistent naming across the enterprise

.PARAMETER PublisherName
    The publisher certificate subject (e.g., 'O=MICROSOFT CORPORATION').

.PARAMETER ProductName
    The product name from file metadata.

.PARAMETER FilePath
    The full file path of the artifact.

.PARAMETER IsSigned
    Whether the file is digitally signed. Default assumes signed if PublisherName provided.

.EXAMPLE
    Get-SuggestedGroup -PublisherName 'O=MICROSOFT CORPORATION' -ProductName 'Microsoft Office Word'
    
    Returns: @{ Vendor = 'Microsoft'; Category = 'Office'; SuggestedGroup = 'Microsoft-Office'; RiskLevel = 'Low' }

.EXAMPLE
    Get-SuggestedGroup -FilePath 'C:\Windows\System32\notepad.exe'
    
    Returns suggestion based on path analysis.

.OUTPUTS
    [PSCustomObject] Result with Success, Data containing suggestion details.
#>
function Get-SuggestedGroup {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$PublisherName,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$ProductName,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$FilePath,

        [Parameter()]
        [bool]$IsSigned = $true
    )

    $result = [PSCustomObject]@{
        Success = $false
        Data    = $null
        Error   = $null
    }

    try {
        # Validate we have at least some input
        if ([string]::IsNullOrWhiteSpace($PublisherName) -and 
            [string]::IsNullOrWhiteSpace($ProductName) -and 
            [string]::IsNullOrWhiteSpace($FilePath)) {
            $result.Error = "At least one of PublisherName, ProductName, or FilePath is required"
            return $result
        }

        # Load known vendors database
        $vendors = Get-KnownVendors

        # Initialize suggestion
        $suggestion = [PSCustomObject]@{
            Vendor          = 'Unknown'
            Category        = 'Other'
            SuggestedGroup  = 'Unknown-Other'
            RiskLevel       = 'Medium'
            Confidence      = 'Low'
            MatchedBy       = 'None'
            Description     = ''
        }

        # Determine signature status
        # Unsigned = IsSigned is explicitly false (caller knows it's unsigned)
        # No publisher + IsSigned true = unknown/path-only query (not necessarily unsigned)
        $explicitlyUnsigned = -not $IsSigned
        $hasPublisher = -not [string]::IsNullOrWhiteSpace($PublisherName)

        # If explicitly marked unsigned, categorize as high risk
        if ($explicitlyUnsigned) {
            $suggestion.Vendor = 'Unsigned'
            $suggestion.Category = 'Review'
            $suggestion.SuggestedGroup = 'Unsigned-Review'
            $suggestion.RiskLevel = 'High'
            $suggestion.Confidence = 'High'
            $suggestion.MatchedBy = 'SignatureStatus'
            $suggestion.Description = 'Unsigned executable requires manual review'

            # Still try to categorize by path if available
            if (-not [string]::IsNullOrWhiteSpace($FilePath)) {
                $pathSuggestion = Get-PathBasedSuggestion -FilePath $FilePath -Vendors $vendors
                if ($pathSuggestion) {
                    $suggestion.Category = $pathSuggestion.Category
                    $suggestion.SuggestedGroup = "Unsigned-$($pathSuggestion.Category)"
                    # For unsigned files, keep High risk - unsigned is inherently risky regardless of path
                    # Only exception: don't show a lower risk than the path suggests
                    # $suggestion.RiskLevel stays 'High' (set above)
                    $suggestion.Description = $pathSuggestion.Description
                }
            }

            $result.Success = $true
            $result.Data = $suggestion
            return $result
        }

        # Try to match publisher to known vendor
        $vendorMatch = $null
        $matchedVendorName = $null

        foreach ($vendorName in $vendors.PSObject.Properties.Name) {
            # Skip metadata properties
            if ($vendorName.StartsWith('_')) { continue }
            
            $vendor = $vendors.$vendorName
            
            foreach ($pattern in $vendor.Patterns) {
                if ($PublisherName -like $pattern) {
                    $vendorMatch = $vendor
                    $matchedVendorName = $vendorName
                    break
                }
            }
            if ($vendorMatch) { break }
        }

        if ($vendorMatch) {
            $suggestion.Vendor = $matchedVendorName
            $suggestion.RiskLevel = $vendorMatch.RiskLevel
            $suggestion.Confidence = 'High'
            $suggestion.MatchedBy = 'Publisher'

            # Try to match product category
            $categoryMatch = $null
            $matchedCategoryName = $null

            if ($vendorMatch.Categories -and -not [string]::IsNullOrWhiteSpace($ProductName)) {
                foreach ($categoryName in $vendorMatch.Categories.PSObject.Properties.Name) {
                    $category = $vendorMatch.Categories.$categoryName
                    
                    # Check product patterns
                    if ($category.ProductPatterns) {
                        foreach ($pattern in $category.ProductPatterns) {
                            if ($ProductName -like $pattern) {
                                $categoryMatch = $category
                                $matchedCategoryName = $categoryName
                                break
                            }
                        }
                    }
                    
                    # Check path patterns if no product match and path available
                    if (-not $categoryMatch -and $category.PathPatterns -and -not [string]::IsNullOrWhiteSpace($FilePath)) {
                        foreach ($pattern in $category.PathPatterns) {
                            if ($FilePath -like $pattern) {
                                $categoryMatch = $category
                                $matchedCategoryName = $categoryName
                                break
                            }
                        }
                    }
                    
                    if ($categoryMatch) { break }
                }
            }

            if ($categoryMatch) {
                $suggestion.Category = $matchedCategoryName
                $suggestion.Description = $categoryMatch.Description
            }
            else {
                $suggestion.Category = 'Other'
                $suggestion.Description = "Recognized vendor: $matchedVendorName"
            }

            $suggestion.SuggestedGroup = "$matchedVendorName-$($suggestion.Category)"
        }
        else {
            # Unknown publisher - try path-based categorization
            if (-not [string]::IsNullOrWhiteSpace($FilePath)) {
                $pathSuggestion = Get-PathBasedSuggestion -FilePath $FilePath -Vendors $vendors
                if ($pathSuggestion) {
                    $suggestion.Category = $pathSuggestion.Category
                    $suggestion.RiskLevel = $pathSuggestion.RiskLevel
                    $suggestion.Description = $pathSuggestion.Description
                    $suggestion.MatchedBy = 'Path'
                    $suggestion.Confidence = 'Medium'
                    $suggestion.SuggestedGroup = "Unknown-$($pathSuggestion.Category)"
                }
            }

            # Extract company name from publisher string if possible
            if (-not [string]::IsNullOrWhiteSpace($PublisherName)) {
                $companyName = Extract-CompanyName -PublisherName $PublisherName
                if ($companyName) {
                    $suggestion.Vendor = $companyName
                    $suggestion.SuggestedGroup = "$companyName-$($suggestion.Category)"
                    $suggestion.MatchedBy = 'PublisherExtracted'
                    $suggestion.Confidence = 'Low'
                }
            }
        }

        $result.Success = $true
        $result.Data = $suggestion
    }
    catch {
        $result.Error = "Failed to suggest group: $($_.Exception.Message)"
    }

    return $result
}

<#
.SYNOPSIS
    Gets the known vendors database.
#>
function Get-KnownVendors {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $dataPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Data\KnownVendors.json'
    
    if (Test-Path $dataPath) {
        $json = Get-Content -Path $dataPath -Raw -Encoding UTF8
        return $json | ConvertFrom-Json
    }
    else {
        # Return minimal embedded fallback
        return [PSCustomObject]@{
            Microsoft = @{
                Patterns  = @('*MICROSOFT*')
                RiskLevel = 'Low'
                Categories = @{
                    Office = @{ ProductPatterns = @('*Office*', '*Word*', '*Excel*'); Description = 'Microsoft Office' }
                    Windows = @{ ProductPatterns = @('*Windows*'); Description = 'Windows components' }
                    Browser = @{ ProductPatterns = @('*Edge*'); Description = 'Microsoft Edge' }
                    Development = @{ ProductPatterns = @('*Visual Studio*'); Description = 'Development tools' }
                }
            }
            Adobe = @{
                Patterns  = @('*ADOBE*')
                RiskLevel = 'Low'
                Categories = @{
                    PDF = @{ ProductPatterns = @('*Acrobat*', '*Reader*'); Description = 'Adobe PDF' }
                    Creative = @{ ProductPatterns = @('*Photoshop*'); Description = 'Creative Suite' }
                }
            }
            Google = @{
                Patterns  = @('*GOOGLE*')
                RiskLevel = 'Low'
                Categories = @{
                    Browser = @{ ProductPatterns = @('*Chrome*'); Description = 'Google Chrome' }
                }
            }
            _PathCategories = @{
                Windows = @{ Patterns = @('C:\Windows\*'); RiskLevel = 'Low'; Description = 'Windows system' }
                ProgramFiles = @{ Patterns = @('C:\Program Files\*'); RiskLevel = 'Low'; Description = 'Program Files' }
                UserInstalled = @{ Patterns = @('*\AppData\*'); RiskLevel = 'Medium'; Description = 'User installed' }
                Downloads = @{ Patterns = @('*\Downloads\*'); RiskLevel = 'High'; Description = 'Downloads folder' }
            }
        }
    }
}

<#
.SYNOPSIS
    Gets suggestion based on file path patterns.
#>
function Get-PathBasedSuggestion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [PSCustomObject]$Vendors
    )

    if (-not $Vendors._PathCategories) {
        return $null
    }

    foreach ($categoryName in $Vendors._PathCategories.PSObject.Properties.Name) {
        $category = $Vendors._PathCategories.$categoryName
        
        foreach ($pattern in $category.Patterns) {
            if ($FilePath -like $pattern) {
                return [PSCustomObject]@{
                    Category    = $categoryName
                    RiskLevel   = $category.RiskLevel
                    Description = $category.Description
                }
            }
        }
    }

    # Default for unmatched paths
    return [PSCustomObject]@{
        Category    = 'Application'
        RiskLevel   = 'Medium'
        Description = 'Unrecognized application path'
    }
}

<#
.SYNOPSIS
    Extracts a clean company name from publisher certificate subject.
#>
function Extract-CompanyName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PublisherName
    )

    # Try to extract O= field
    if ($PublisherName -match 'O=([^,]+)') {
        $company = $Matches[1].Trim()
        
        # Clean up common suffixes
        $company = $company -replace '\s*(INC\.?|LLC|LTD\.?|CORP\.?|CORPORATION|GMBH|S\.?A\.?|PLC)$', ''
        $company = $company.Trim()
        
        # Convert to PascalCase for consistency
        $company = (Get-Culture).TextInfo.ToTitleCase($company.ToLower())
        
        # Remove spaces for group name
        $company = $company -replace '\s+', ''
        
        return $company
    }

    return $null
}
