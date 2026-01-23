<#
.SYNOPSIS
    Input validation helpers for GA-AppLocker.

.DESCRIPTION
    Centralized validation functions to ensure data integrity across all modules.
    Provides:
    - Type validators (hash, SID, GUID, etc.)
    - Domain-specific validators (collection types, actions, statuses)
    - Assertion helpers for parameter validation
    - Sanitization functions

.NOTES
    Author: GA-AppLocker Team
    Version: 1.0.0
#>

#region ===== CONSTANTS =====
# Valid AppLocker collection types
$script:ValidCollectionTypes = @('Exe', 'Dll', 'Msi', 'Script', 'Appx')

# Valid rule actions
$script:ValidRuleActions = @('Allow', 'Deny')

# Valid rule statuses
$script:ValidRuleStatuses = @('Pending', 'Approved', 'Rejected', 'Review')

# Valid policy statuses
$script:ValidPolicyStatuses = @('Draft', 'Active', 'Archived')

# Valid enforcement modes
$script:ValidEnforcementModes = @('NotConfigured', 'AuditOnly', 'Enabled')

# Valid tier values
$script:ValidTiers = @(0, 1, 2)
#endregion

#region ===== TYPE VALIDATORS =====

<#
.SYNOPSIS
    Validates a SHA256 hash string.

.PARAMETER Hash
    The hash string to validate.

.EXAMPLE
    Test-ValidHash -Hash 'A1B2C3D4E5F6...'

.OUTPUTS
    [bool] True if valid SHA256 hash format
#>
function Test-ValidHash {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Hash
    )

    if ([string]::IsNullOrWhiteSpace($Hash)) { return $false }
    return $Hash -match '^[A-Fa-f0-9]{64}$'
}

<#
.SYNOPSIS
    Validates a Windows SID string.

.PARAMETER Sid
    The SID string to validate.

.EXAMPLE
    Test-ValidSid -Sid 'S-1-1-0'

.OUTPUTS
    [bool] True if valid SID format
#>
function Test-ValidSid {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Sid
    )

    if ([string]::IsNullOrWhiteSpace($Sid)) { return $false }
    # SID format: S-1-{authority}-{sub-authorities...}
    return $Sid -match '^S-1-\d+(-\d+)*$'
}

<#
.SYNOPSIS
    Validates a GUID string.

.PARAMETER Guid
    The GUID string to validate.

.EXAMPLE
    Test-ValidGuid -Guid '12345678-1234-1234-1234-123456789abc'

.OUTPUTS
    [bool] True if valid GUID format
#>
function Test-ValidGuid {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Guid
    )

    if ([string]::IsNullOrWhiteSpace($Guid)) { return $false }
    $parsedGuid = [guid]::Empty
    return [guid]::TryParse($Guid, [ref]$parsedGuid)
}

<#
.SYNOPSIS
    Validates a file path string.

.PARAMETER Path
    The path string to validate.

.PARAMETER MustExist
    If specified, also checks if the path exists.

.EXAMPLE
    Test-ValidPath -Path 'C:\Program Files\App\app.exe'

.EXAMPLE
    Test-ValidPath -Path 'C:\Config\settings.json' -MustExist

.OUTPUTS
    [bool] True if valid path format (and exists if MustExist specified)
#>
function Test-ValidPath {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter()]
        [switch]$MustExist
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    
    # Check for invalid path characters
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    foreach ($char in $invalidChars) {
        if ($Path.Contains($char)) { return $false }
    }

    # Basic path format check
    if (-not ($Path -match '^[A-Za-z]:\\' -or $Path -match '^\\\\')) {
        return $false
    }

    if ($MustExist) {
        return Test-Path -Path $Path -ErrorAction SilentlyContinue
    }

    return $true
}

<#
.SYNOPSIS
    Validates a Distinguished Name (DN) string.

.PARAMETER DistinguishedName
    The DN string to validate.

.EXAMPLE
    Test-ValidDistinguishedName -DistinguishedName 'OU=Computers,DC=corp,DC=local'

.OUTPUTS
    [bool] True if valid DN format
#>
function Test-ValidDistinguishedName {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$DistinguishedName
    )

    if ([string]::IsNullOrWhiteSpace($DistinguishedName)) { return $false }
    # Basic DN format: at least one component like CN=, OU=, DC=
    return $DistinguishedName -match '^(CN|OU|DC)=[^,]+(,(CN|OU|DC)=[^,]+)*$'
}

<#
.SYNOPSIS
    Validates a hostname string.

.PARAMETER Hostname
    The hostname string to validate.

.EXAMPLE
    Test-ValidHostname -Hostname 'SERVER01'

.OUTPUTS
    [bool] True if valid hostname format
#>
function Test-ValidHostname {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Hostname
    )

    if ([string]::IsNullOrWhiteSpace($Hostname)) { return $false }
    # NetBIOS name: 1-15 chars, alphanumeric and hyphen, not starting with hyphen
    return $Hostname -match '^[A-Za-z0-9][A-Za-z0-9\-]{0,14}$'
}

#endregion

#region ===== DOMAIN VALIDATORS =====

<#
.SYNOPSIS
    Validates an AppLocker collection type.

.PARAMETER CollectionType
    The collection type to validate.

.EXAMPLE
    Test-ValidCollectionType -CollectionType 'Exe'

.OUTPUTS
    [bool] True if valid collection type
#>
function Test-ValidCollectionType {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$CollectionType
    )

    if ([string]::IsNullOrWhiteSpace($CollectionType)) { return $false }
    return $CollectionType -in $script:ValidCollectionTypes
}

<#
.SYNOPSIS
    Validates an AppLocker rule action.

.PARAMETER Action
    The action to validate.

.EXAMPLE
    Test-ValidRuleAction -Action 'Allow'

.OUTPUTS
    [bool] True if valid action
#>
function Test-ValidRuleAction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Action
    )

    if ([string]::IsNullOrWhiteSpace($Action)) { return $false }
    return $Action -in $script:ValidRuleActions
}

<#
.SYNOPSIS
    Validates a rule status.

.PARAMETER Status
    The status to validate.

.EXAMPLE
    Test-ValidRuleStatus -Status 'Approved'

.OUTPUTS
    [bool] True if valid status
#>
function Test-ValidRuleStatus {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Status
    )

    if ([string]::IsNullOrWhiteSpace($Status)) { return $false }
    return $Status -in $script:ValidRuleStatuses
}

<#
.SYNOPSIS
    Validates a policy status.

.PARAMETER Status
    The status to validate.

.EXAMPLE
    Test-ValidPolicyStatus -Status 'Active'

.OUTPUTS
    [bool] True if valid status
#>
function Test-ValidPolicyStatus {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Status
    )

    if ([string]::IsNullOrWhiteSpace($Status)) { return $false }
    return $Status -in $script:ValidPolicyStatuses
}

<#
.SYNOPSIS
    Validates an enforcement mode.

.PARAMETER Mode
    The enforcement mode to validate.

.EXAMPLE
    Test-ValidEnforcementMode -Mode 'AuditOnly'

.OUTPUTS
    [bool] True if valid mode
#>
function Test-ValidEnforcementMode {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Mode
    )

    if ([string]::IsNullOrWhiteSpace($Mode)) { return $false }
    return $Mode -in $script:ValidEnforcementModes
}

<#
.SYNOPSIS
    Validates a tier value.

.PARAMETER Tier
    The tier to validate (0, 1, or 2).

.EXAMPLE
    Test-ValidTier -Tier 1

.OUTPUTS
    [bool] True if valid tier
#>
function Test-ValidTier {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [int]$Tier
    )

    return $Tier -in $script:ValidTiers
}

#endregion

#region ===== ASSERTION HELPERS =====

<#
.SYNOPSIS
    Asserts that a value is not null or empty.

.PARAMETER Value
    The value to check.

.PARAMETER ParameterName
    Name of the parameter for error message.

.PARAMETER Message
    Custom error message.

.EXAMPLE
    Assert-NotNullOrEmpty -Value $hash -ParameterName 'Hash'

.OUTPUTS
    Throws if validation fails, otherwise returns nothing
#>
function Assert-NotNullOrEmpty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        $Value,

        [Parameter(Mandatory)]
        [string]$ParameterName,

        [Parameter()]
        [string]$Message
    )

    $isInvalid = $false
    if ($null -eq $Value) { $isInvalid = $true }
    elseif ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) { $isInvalid = $true }
    elseif ($Value -is [array] -and $Value.Count -eq 0) { $isInvalid = $true }

    if ($isInvalid) {
        $errorMsg = if ($Message) { $Message } else { "Parameter '$ParameterName' cannot be null or empty." }
        throw [System.ArgumentException]::new($errorMsg, $ParameterName)
    }
}

<#
.SYNOPSIS
    Asserts that a numeric value is within a range.

.PARAMETER Value
    The value to check.

.PARAMETER Minimum
    Minimum allowed value (inclusive).

.PARAMETER Maximum
    Maximum allowed value (inclusive).

.PARAMETER ParameterName
    Name of the parameter for error message.

.EXAMPLE
    Assert-InRange -Value $port -Minimum 1 -Maximum 65535 -ParameterName 'Port'

.OUTPUTS
    Throws if validation fails, otherwise returns nothing
#>
function Assert-InRange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Value,

        [Parameter()]
        $Minimum,

        [Parameter()]
        $Maximum,

        [Parameter(Mandatory)]
        [string]$ParameterName
    )

    if ($null -ne $Minimum -and $Value -lt $Minimum) {
        throw [System.ArgumentOutOfRangeException]::new(
            $ParameterName,
            $Value,
            "Value must be at least $Minimum."
        )
    }

    if ($null -ne $Maximum -and $Value -gt $Maximum) {
        throw [System.ArgumentOutOfRangeException]::new(
            $ParameterName,
            $Value,
            "Value must be at most $Maximum."
        )
    }
}

<#
.SYNOPSIS
    Asserts that a value matches a pattern.

.PARAMETER Value
    The value to check.

.PARAMETER Pattern
    Regex pattern to match.

.PARAMETER ParameterName
    Name of the parameter for error message.

.PARAMETER Message
    Custom error message.

.EXAMPLE
    Assert-MatchesPattern -Value $hash -Pattern '^[A-Fa-f0-9]{64}$' -ParameterName 'Hash' -Message 'Invalid SHA256 hash format'

.OUTPUTS
    Throws if validation fails, otherwise returns nothing
#>
function Assert-MatchesPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory)]
        [string]$Pattern,

        [Parameter(Mandatory)]
        [string]$ParameterName,

        [Parameter()]
        [string]$Message
    )

    if (-not ($Value -match $Pattern)) {
        $errorMsg = if ($Message) { $Message } else { "Parameter '$ParameterName' does not match required pattern." }
        throw [System.ArgumentException]::new($errorMsg, $ParameterName)
    }
}

<#
.SYNOPSIS
    Asserts that a value is in a set of allowed values.

.PARAMETER Value
    The value to check.

.PARAMETER AllowedValues
    Array of allowed values.

.PARAMETER ParameterName
    Name of the parameter for error message.

.EXAMPLE
    Assert-InSet -Value $action -AllowedValues @('Allow', 'Deny') -ParameterName 'Action'

.OUTPUTS
    Throws if validation fails, otherwise returns nothing
#>
function Assert-InSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Value,

        [Parameter(Mandatory)]
        [array]$AllowedValues,

        [Parameter(Mandatory)]
        [string]$ParameterName
    )

    if ($Value -notin $AllowedValues) {
        $allowedList = $AllowedValues -join ', '
        throw [System.ArgumentException]::new(
            "Parameter '$ParameterName' must be one of: $allowedList. Got: '$Value'",
            $ParameterName
        )
    }
}

#endregion

#region ===== SANITIZATION =====

<#
.SYNOPSIS
    Sanitizes a string for safe use in file names.

.PARAMETER Value
    The string to sanitize.

.PARAMETER Replacement
    Character to replace invalid chars with. Default is underscore.

.EXAMPLE
    $safeName = ConvertTo-SafeFileName -Value 'My Rule: Test <1>'
    # Returns: 'My Rule_ Test _1_'

.OUTPUTS
    [string] Sanitized string safe for file names
#>
function ConvertTo-SafeFileName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Value,

        [Parameter()]
        [char]$Replacement = '_'
    )

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $result = $Value
    foreach ($char in $invalidChars) {
        $result = $result.Replace($char, $Replacement)
    }
    return $result
}

<#
.SYNOPSIS
    Sanitizes a string for safe use in XML content.

.PARAMETER Value
    The string to sanitize.

.EXAMPLE
    $safeXml = ConvertTo-SafeXmlString -Value 'Test <value> & more'
    # Returns: 'Test &lt;value&gt; &amp; more'

.OUTPUTS
    [string] XML-escaped string
#>
function ConvertTo-SafeXmlString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrEmpty($Value)) { return $Value }
    return [System.Security.SecurityElement]::Escape($Value)
}

#endregion

#region ===== GET VALID VALUES =====

<#
.SYNOPSIS
    Gets the list of valid values for a domain type.

.PARAMETER Type
    The type to get valid values for.

.EXAMPLE
    Get-ValidValues -Type 'CollectionType'

.OUTPUTS
    [string[]] Array of valid values
#>
function Get-ValidValues {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('CollectionType', 'RuleAction', 'RuleStatus', 'PolicyStatus', 'EnforcementMode', 'Tier')]
        [string]$Type
    )

    switch ($Type) {
        'CollectionType' { return $script:ValidCollectionTypes }
        'RuleAction' { return $script:ValidRuleActions }
        'RuleStatus' { return $script:ValidRuleStatuses }
        'PolicyStatus' { return $script:ValidPolicyStatuses }
        'EnforcementMode' { return $script:ValidEnforcementModes }
        'Tier' { return $script:ValidTiers }
    }
}

#endregion
