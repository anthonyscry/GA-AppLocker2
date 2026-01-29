---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Remove-RuleFromRepository

## SYNOPSIS
Removes a rule from the repository.

## SYNTAX

```
Remove-RuleFromRepository [-RuleId] <String> [<CommonParameters>]
```

## DESCRIPTION
Deletes a rule and handles cache invalidation and event publishing.

## EXAMPLES

### EXAMPLE 1
```
Remove-RuleFromRepository -RuleId 'rule-123'
```

## PARAMETERS

### -RuleId
The ID of the rule to remove.

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

### [PSCustomObject] Result object with Success property
## NOTES

## RELATED LINKS
