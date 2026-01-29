---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Add-RuleToPolicy

## SYNOPSIS
Adds one or more rules to a policy.

## SYNTAX

```
Add-RuleToPolicy [-PolicyId] <String> [-RuleId] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Adds one or more rules to a policy.

## EXAMPLES

### EXAMPLE 1
```
Add-RuleToPolicy -PolicyId "abc123" -RuleId "rule1", "rule2"
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
The rule ID(s) to add.

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
