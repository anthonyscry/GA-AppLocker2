---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-AppLockerRuleConditions

## SYNOPSIS
Validates rule conditions for all rule types.

## SYNTAX

```
Test-AppLockerRuleConditions [-XmlPath] <String> [<CommonParameters>]
```

## DESCRIPTION
Validates:
- Publisher rules: PublisherName non-empty, BinaryVersionRange format
- Hash rules: SHA256 format (0x prefix + 64 hex chars), Type=SHA256, SourceFileName/Length
- Path rules: Valid path format, warns about user-writable locations

## EXAMPLES

### EXAMPLE 1
```
Test-AppLockerRuleConditions -XmlPath "C:\Policies\baseline.xml"
```

## PARAMETERS

### -XmlPath
Path to the AppLocker policy XML file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] with Success, Errors, Warnings, RuleStats properties
## NOTES

## RELATED LINKS
