---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-RuleCountsFromRepository

## SYNOPSIS
Gets rule counts with caching.

## SYNTAX

```
Get-RuleCountsFromRepository [-BypassCache] [<CommonParameters>]
```

## DESCRIPTION
Returns counts of rules by status, using cache for performance.

## EXAMPLES

### EXAMPLE 1
```
$counts = Get-RuleCountsFromRepository
```

## PARAMETERS

### -BypassCache
Skip cache and query storage directly.

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

### [PSCustomObject] Counts by status
## NOTES

## RELATED LINKS
