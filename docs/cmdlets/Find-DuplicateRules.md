---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Find-DuplicateRules

## SYNOPSIS
Finds duplicate rules without removing them.

## SYNTAX

```
Find-DuplicateRules [[-RuleType] <String>] [<CommonParameters>]
```

## DESCRIPTION
Scans the rule database and returns information about duplicate rules.
Use this to preview what would be affected by Remove-DuplicateRules.

## EXAMPLES

### EXAMPLE 1
```
Find-DuplicateRules -RuleType Hash
```

Returns all hash rule duplicates.

## PARAMETERS

### -RuleType
Type of rules to check: Hash, Publisher, Path, or All.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with duplicate groups and counts.
## NOTES

## RELATED LINKS
