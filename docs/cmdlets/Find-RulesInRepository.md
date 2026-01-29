---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Find-RulesInRepository

## SYNOPSIS
Finds rules in the repository with filtering.

## SYNTAX

```
Find-RulesInRepository [[-Filter] <Hashtable>] [[-Take] <Int32>] [[-Skip] <Int32>] [[-OrderBy] <String>]
 [-Descending] [-BypassCache] [<CommonParameters>]
```

## DESCRIPTION
Queries rules with flexible filtering options.
Results are cached
for repeated queries with same parameters.

## EXAMPLES

### EXAMPLE 1
```
$pendingRules = Find-RulesInRepository -Filter @{ Status = 'Pending' } -Take 100
```

### EXAMPLE 2
```
$msRules = Find-RulesInRepository -Filter @{ PublisherPattern = '*MICROSOFT*' }
```

## PARAMETERS

### -Filter
Hashtable of filter conditions.
Supports:
- Status: Rule status (Pending, Approved, etc.)
- RuleType: Hash, Publisher, Path
- CollectionType: Exe, Dll, Msi, Script, Appx
- PublisherPattern: Wildcard pattern for publisher name
- Search: Text search across name/description

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -Take
Maximum number of results to return.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip
Number of results to skip (for pagination).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrderBy
Property to sort by.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: CreatedDate
Accept pipeline input: False
Accept wildcard characters: False
```

### -Descending
Sort in descending order.

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

### [PSCustomObject[]] Array of matching rules
## NOTES

## RELATED LINKS
