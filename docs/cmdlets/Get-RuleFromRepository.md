---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-RuleFromRepository

## SYNOPSIS
Gets a rule by its ID from the repository.

## SYNTAX

```
Get-RuleFromRepository [-RuleId] <String> [-BypassCache] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a single rule by ID, using cache if available.

## EXAMPLES

### EXAMPLE 1
```
$rule = Get-RuleFromRepository -RuleId 'rule-123'
```

## PARAMETERS

### -RuleId
The unique identifier of the rule.

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

### -BypassCache
If specified, bypasses the cache and reads from storage.

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

### [PSCustomObject] The rule object, or $null if not found
## NOTES

## RELATED LINKS
