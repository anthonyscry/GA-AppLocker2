---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Compare-RuleVersions

## SYNOPSIS
Compares two versions of a rule.

## SYNTAX

```
Compare-RuleVersions [-RuleId] <String> [-Version1] <Int32> [[-Version2] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Compares two versions of a rule.
Returns the differences found between items.

## EXAMPLES

### EXAMPLE 1
```
Compare-RuleVersions -RuleId '12345678-...' -Version1 1 -Version2 3
```

## PARAMETERS

### -RuleId
The rule ID to compare versions for.

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

### -Version1
First version number.

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

### -Version2
Second version number (default: current).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
