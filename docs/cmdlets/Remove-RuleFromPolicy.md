---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Remove-RuleFromPolicy

## SYNOPSIS
Removes one or more rules from a policy.

## SYNTAX

```
Remove-RuleFromPolicy [-PolicyId] <String> [-RuleId] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Removes one or more rules from a policy.

## EXAMPLES

### EXAMPLE 1
```
Remove-RuleFromPolicy -PolicyId "abc123" -RuleId "rule1"
```

## PARAMETERS

### -PolicyId
The unique identifier of the policy.

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

### -RuleId
The rule ID(s) to remove.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
