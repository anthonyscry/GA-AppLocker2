---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Save-RulesBulk

## SYNOPSIS
Bulk storage operations for high-performance rule management.

## SYNTAX

```
Save-RulesBulk [-Rules] <Array> [-UpdateIndex] [[-ProgressCallback] <ScriptBlock>] [<CommonParameters>]
```

## DESCRIPTION
Provides batch write and index update operations to minimize disk I/O.
Used by Invoke-BatchRuleGeneration for 10x+ performance improvement.

## EXAMPLES

### EXAMPLE 1
```
Save-RulesBulk
```

# Save RulesBulk

## PARAMETERS

### -Rules
{{ Fill Rules Description }}

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateIndex
{{ Fill UpdateIndex Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressCallback
{{ Fill ProgressCallback Description }}

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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
