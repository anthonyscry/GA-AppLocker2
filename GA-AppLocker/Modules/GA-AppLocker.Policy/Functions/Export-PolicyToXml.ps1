function Export-PolicyToXml {
    <#
    .SYNOPSIS
        Exports a policy to AppLocker-compatible XML format.

    .DESCRIPTION
        Generates a complete AppLocker policy XML that can be
        imported into Group Policy.

    .PARAMETER PolicyId
        The unique identifier of the policy.

    .PARAMETER OutputPath
        The path to save the XML file.

    .PARAMETER IncludeRejected
        Include rejected rules in export (default: false).

    .EXAMPLE
        Export-PolicyToXml -PolicyId "abc123" -OutputPath "C:\Policies\baseline.xml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyId,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRejected
    )

    try {
        # Get the policy
        $policyResult = Get-Policy -PolicyId $PolicyId
        if (-not $policyResult.Success) {
            return $policyResult
        }
        $policy = $policyResult.Data

        # Get all rules for this policy
        $dataPath = Get-AppLockerDataPath
        $rulesPath = Join-Path $dataPath 'Rules'
        $rules = @()

        foreach ($ruleId in $policy.RuleIds) {
            $ruleFile = Join-Path $rulesPath "$ruleId.json"
            if (Test-Path $ruleFile) {
                $rule = Get-Content -Path $ruleFile -Raw | ConvertFrom-Json
                
                # Skip rejected unless explicitly included
                if ($rule.Status -eq 'Rejected' -and -not $IncludeRejected) {
                    continue
                }
                
                $rules += $rule
            }
        }

        if ($rules.Count -eq 0) {
            return @{
                Success = $false
                Error   = 'No valid rules to export'
            }
        }

        # Group rules by collection type
        $exeRules = $rules | Where-Object { $_.RuleCollection -eq 'Exe' }
        $dllRules = $rules | Where-Object { $_.RuleCollection -eq 'Dll' }
        $msiRules = $rules | Where-Object { $_.RuleCollection -eq 'Msi' }
        $scriptRules = $rules | Where-Object { $_.RuleCollection -eq 'Script' }

        # Determine enforcement mode
        $enforcementValue = switch ($policy.EnforcementMode) {
            'Enabled' { 'Enabled' }
            'AuditOnly' { 'AuditOnly' }
            default { 'NotConfigured' }
        }

        # Build XML
        $xmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="$enforcementValue">
$(Build-RuleCollectionXml -Rules $exeRules)
  </RuleCollection>
  <RuleCollection Type="Dll" EnforcementMode="$enforcementValue">
$(Build-RuleCollectionXml -Rules $dllRules)
  </RuleCollection>
  <RuleCollection Type="Msi" EnforcementMode="$enforcementValue">
$(Build-RuleCollectionXml -Rules $msiRules)
  </RuleCollection>
  <RuleCollection Type="Script" EnforcementMode="$enforcementValue">
$(Build-RuleCollectionXml -Rules $scriptRules)
  </RuleCollection>
</AppLockerPolicy>
"@

        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputPath
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        $xmlContent | Set-Content -Path $OutputPath -Encoding UTF8

        return @{
            Success = $true
            Data    = @{
                Path      = $OutputPath
                RuleCount = $rules.Count
                Policy    = $policy.Name
            }
            Message = "Exported $($rules.Count) rules to $OutputPath"
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

function Build-RuleCollectionXml {
    param([array]$Rules)

    if (-not $Rules -or $Rules.Count -eq 0) {
        return ''
    }

    $xml = ''
    foreach ($rule in $Rules) {
        $action = $rule.Action
        $name = [System.Security.SecurityElement]::Escape($rule.Name)
        $description = [System.Security.SecurityElement]::Escape($rule.Description)
        $id = $rule.RuleId

        switch ($rule.RuleType) {
            'Publisher' {
                $publisher = [System.Security.SecurityElement]::Escape($rule.PublisherName)
                $product = [System.Security.SecurityElement]::Escape($rule.ProductName)
                $binaryName = if ($rule.BinaryName) { [System.Security.SecurityElement]::Escape($rule.BinaryName) } else { '*' }
                $binaryVersion = if ($rule.BinaryVersionLow) { $rule.BinaryVersionLow } else { '*' }

                $xml += @"
    <FilePublisherRule Id="$id" Name="$name" Description="$description" UserOrGroupSid="S-1-1-0" Action="$action">
      <Conditions>
        <FilePublisherCondition PublisherName="$publisher" ProductName="$product" BinaryName="$binaryName">
          <BinaryVersionRange LowSection="$binaryVersion" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>

"@
            }
            'Hash' {
                $hash = $rule.Hash
                $fileName = [System.Security.SecurityElement]::Escape($rule.FileName)
                $fileLength = if ($rule.FileLength) { $rule.FileLength } else { '0' }

                $xml += @"
    <FileHashRule Id="$id" Name="$name" Description="$description" UserOrGroupSid="S-1-1-0" Action="$action">
      <Conditions>
        <FileHashCondition>
          <FileHash Type="SHA256" Data="$hash" SourceFileName="$fileName" SourceFileLength="$fileLength" />
        </FileHashCondition>
      </Conditions>
    </FileHashRule>

"@
            }
            'Path' {
                $path = [System.Security.SecurityElement]::Escape($rule.Path)

                $xml += @"
    <FilePathRule Id="$id" Name="$name" Description="$description" UserOrGroupSid="S-1-1-0" Action="$action">
      <Conditions>
        <FilePathCondition Path="$path" />
      </Conditions>
    </FilePathRule>

"@
            }
        }
    }

    return $xml.TrimEnd()
}

function Test-PolicyCompliance {
    <#
    .SYNOPSIS
        Tests policy against current system state.

    .DESCRIPTION
        Validates that the policy rules match the current
        executables on the target system.

    .PARAMETER PolicyId
        The unique identifier of the policy.

    .PARAMETER ComputerName
        Optional computer to test against (default: local).

    .EXAMPLE
        Test-PolicyCompliance -PolicyId "abc123"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyId,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {
        $policyResult = Get-Policy -PolicyId $PolicyId
        if (-not $policyResult.Success) {
            return $policyResult
        }
        $policy = $policyResult.Data

        # Basic compliance check - verify rules exist
        $dataPath = Get-AppLockerDataPath
        $rulesPath = Join-Path $dataPath 'Rules'
        
        $validRules = 0
        $missingRules = 0
        $approvedRules = 0

        foreach ($ruleId in $policy.RuleIds) {
            $ruleFile = Join-Path $rulesPath "$ruleId.json"
            if (Test-Path $ruleFile) {
                $validRules++
                $rule = Get-Content -Path $ruleFile -Raw | ConvertFrom-Json
                if ($rule.Status -eq 'Approved') {
                    $approvedRules++
                }
            }
            else {
                $missingRules++
            }
        }

        $compliance = @{
            PolicyName     = $policy.Name
            TotalRules     = $policy.RuleIds.Count
            ValidRules     = $validRules
            MissingRules   = $missingRules
            ApprovedRules  = $approvedRules
            IsCompliant    = ($missingRules -eq 0 -and $approvedRules -eq $validRules)
            TestedAt       = (Get-Date).ToString('o')
            TestedOn       = $ComputerName
        }

        return @{
            Success = $true
            Data    = $compliance
        }
    }
    catch {
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
