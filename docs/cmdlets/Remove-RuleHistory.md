---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Remove-RuleHistory

## SYNOPSIS
Removes all history for a rule.

## SYNTAX

```
Remove-RuleHistory [-RuleId] <String> [<CommonParameters>]
```

## DESCRIPTION
Removes all history for a rule.
Permanently removes the item from storage.

## EXAMPLES

### EXAMPLE 1
```
Remove-RuleHistory -RuleId '12345678-...'
```

## PARAMETERS

### -RuleId
The rule ID to remove history for.

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

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
