---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-CacheStatistics

## SYNOPSIS
Gets cache statistics.

## SYNTAX

```
Get-CacheStatistics [-Reset] [<CommonParameters>]
```

## DESCRIPTION
Returns statistics about cache usage including hits, misses, and evictions.

## EXAMPLES

### EXAMPLE 1
```
Get-CacheStatistics
```

### EXAMPLE 2
```
Get-CacheStatistics -Reset
```

## PARAMETERS

### -Reset
If specified, resets statistics after returning them.

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

### [PSCustomObject] Cache statistics
## NOTES

## RELATED LINKS
