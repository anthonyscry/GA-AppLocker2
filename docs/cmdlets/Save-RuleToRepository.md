---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Save-RuleToRepository

## SYNOPSIS
Saves a rule to the repository.

## SYNTAX

```
Save-RuleToRepository [-Rule] <PSObject> [-IsNew] [<CommonParameters>]
```

## DESCRIPTION
Creates or updates a rule in the repository.
Handles cache invalidation
and event publishing.

## EXAMPLES

### EXAMPLE 1
```
Save-RuleToRepository -Rule $rule
```

### EXAMPLE 2
```
Save-RuleToRepository -Rule $newRule -IsNew
```

## PARAMETERS

### -Rule
The rule object to save.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsNew
If specified, treats this as a new rule (for event publishing).

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result object with Success and Data properties
## NOTES

## RELATED LINKS
