---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Remove-DuplicateRules

## SYNOPSIS
Finds and removes duplicate AppLocker rules.

## SYNTAX

```
Remove-DuplicateRules [[-RuleType] <String>] [[-Strategy] <String>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Identifies duplicate rules based on their key attributes and removes
redundant copies while keeping one rule per unique combination.

Duplicate detection logic:
- Hash rules: Same Hash value
- Publisher rules: Same PublisherName + ProductName + CollectionType
- Path rules: Same Path + CollectionType

## EXAMPLES

### EXAMPLE 1
```
Remove-DuplicateRules -RuleType Hash -WhatIf
```

Shows what hash rule duplicates would be removed.

### EXAMPLE 2
```
Remove-DuplicateRules -RuleType All -Strategy KeepOldest
```

Removes all duplicate rules, keeping the oldest of each set.

## PARAMETERS

### -RuleType
Type of rules to check for duplicates: Hash, Publisher, Path, or All.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -Strategy
Strategy for choosing which duplicate to keep:
- KeepOldest: Keep the rule with earliest CreatedDate (default)
- KeepNewest: Keep the rule with latest CreatedDate
- KeepApproved: Keep approved rules over pending/rejected

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: KeepOldest
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Skip confirmation prompt for large deletions.

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

### -WhatIf
Preview what would be removed without making changes.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, RemovedCount, and details.
## NOTES

## RELATED LINKS
