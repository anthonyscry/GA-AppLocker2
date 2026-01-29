---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Clear-AppLockerCache

## SYNOPSIS
Removes items from the cache.

## SYNTAX

```
Clear-AppLockerCache [[-Pattern] <String>] [[-Key] <String>] [<CommonParameters>]
```

## DESCRIPTION
Clears cached items matching a pattern or all items if no pattern specified.

## EXAMPLES

### EXAMPLE 1
```
Clear-AppLockerCache
```

# Clears all cached items

### EXAMPLE 2
```
Clear-AppLockerCache -Pattern 'Rule*'
```

# Clears all items with keys starting with 'Rule'

### EXAMPLE 3
```
Clear-AppLockerCache -Key 'RuleCounts'
```

# Removes specific cache entry

## PARAMETERS

### -Pattern
Wildcard pattern to match cache keys.
If not specified, clears entire cache.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Key
Specific key to remove.

```yaml
Type: String
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

### [int] Number of items removed
## NOTES

## RELATED LINKS
