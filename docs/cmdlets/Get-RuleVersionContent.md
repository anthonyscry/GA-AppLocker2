---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-RuleVersionContent

## SYNOPSIS
Gets the full content of a specific rule version.

## SYNTAX

```
Get-RuleVersionContent [-RuleId] <String> [-Version] <Int32> [<CommonParameters>]
```

## DESCRIPTION
Gets the full content of a specific rule version.
Returns the requested data in a standard result object.

## EXAMPLES

### EXAMPLE 1
```
Get-RuleVersionContent -RuleId '12345678-...' -Version 2
```

## PARAMETERS

### -RuleId
The rule ID.

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

### -Version
The version number.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
