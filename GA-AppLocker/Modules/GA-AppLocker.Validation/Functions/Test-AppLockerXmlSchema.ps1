function Test-AppLockerXmlSchema {
    <#
    .SYNOPSIS
        Validates AppLocker policy XML against Microsoft schema requirements.

    .DESCRIPTION
        Performs structural validation of AppLocker XML including:
        - Root element validation
        - Required Version attribute
        - RuleCollection Type (case-sensitive: Appx, Dll, Exe, Msi, Script)
        - EnforcementMode (case-sensitive: NotConfigured, AuditOnly, Enabled)
        - Rule counting per collection

    .PARAMETER XmlPath
        Path to the AppLocker policy XML file.

    .PARAMETER XmlContent
        XML content as string (alternative to XmlPath).

    .OUTPUTS
        [PSCustomObject] with Success, Errors, Warnings, Details properties

    .EXAMPLE
        Test-AppLockerXmlSchema -XmlPath "C:\Policies\baseline.xml"

    .EXAMPLE
        Test-AppLockerXmlSchema -XmlContent $xmlString
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateScript({ Test-Path $_ })]
        [string]$XmlPath,

        [Parameter(Mandatory, ParameterSetName = 'Content')]
        [string]$XmlContent
    )

    $result = [PSCustomObject]@{
        Success  = $false
        Errors   = [System.Collections.ArrayList]::new()
        Warnings = [System.Collections.ArrayList]::new()
        Details  = [PSCustomObject]@{
            RootElement      = $null
            RuleCollections  = @()
            TotalRules       = 0
            ValidationTime   = $null
        }
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Load XML
        [xml]$policy = if ($XmlPath) { Get-Content $XmlPath -Raw } else { $XmlContent }

        # 1. Validate root element
        if ($policy.DocumentElement.LocalName -ne 'AppLockerPolicy') {
            [void]$result.Errors.Add("Root element must be 'AppLockerPolicy', found: $($policy.DocumentElement.LocalName)")
            return $result
        }
        $result.Details.RootElement = 'AppLockerPolicy'

        # 2. Validate Version attribute
        $version = $policy.AppLockerPolicy.Version
        if ([string]::IsNullOrEmpty($version)) {
            [void]$result.Errors.Add("AppLockerPolicy missing required 'Version' attribute")
        }
        elseif ($version -notmatch '^\d+$') {
            [void]$result.Errors.Add("Version must be numeric, found: $version")
        }

        # 3. Validate RuleCollections
        $validCollections = @('Appx', 'Dll', 'Exe', 'Msi', 'Script')
        $collections = $policy.AppLockerPolicy.RuleCollection

        if (-not $collections) {
            [void]$result.Warnings.Add("No RuleCollections found in policy")
        }
        else {
            foreach ($collection in $collections) {
                $type = $collection.Type

                # Validate collection type
                if ($type -cnotin $validCollections) {
                    [void]$result.Errors.Add("Invalid RuleCollection Type: '$type'. Must be one of: $($validCollections -join ', ') (case-sensitive)")
                }

                # Validate EnforcementMode
                $mode = $collection.EnforcementMode
                $validModes = @('NotConfigured', 'AuditOnly', 'Enabled')
                if ($mode -cnotin $validModes) {
                    [void]$result.Errors.Add("RuleCollection '$type' has invalid EnforcementMode: '$mode'. Must be: $($validModes -join ', ')")
                }

                $result.Details.RuleCollections += $type

                # Count rules
                $ruleCount = 0
                $ruleCount += ($collection.FilePublisherRule | Measure-Object).Count
                $ruleCount += ($collection.FileHashRule | Measure-Object).Count
                $ruleCount += ($collection.FilePathRule | Measure-Object).Count
                $result.Details.TotalRules += $ruleCount
            }
        }

        $result.Success = ($result.Errors.Count -eq 0)
    }
    catch {
        [void]$result.Errors.Add("XML parsing failed: $($_.Exception.Message)")
    }
    finally {
        $stopwatch.Stop()
        $result.Details.ValidationTime = $stopwatch.Elapsed
    }

    return $result
}
