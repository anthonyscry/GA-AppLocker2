---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-CachedValue

## SYNOPSIS
Gets a cached value or creates it using a factory function.

## SYNTAX

```
Get-CachedValue [-Key] <String> [[-MaxAgeSeconds] <Int32>] [[-Factory] <ScriptBlock>] [-ForceRefresh]
 [<CommonParameters>]
```

## DESCRIPTION
Retrieves a value from cache if it exists and hasn't expired.
If the value is missing or expired, executes the factory function
to create a new value and caches it.

## EXAMPLES

### EXAMPLE 1
```
$ruleCounts = Get-CachedValue -Key 'RuleCounts' -MaxAgeSeconds 60 -Factory { Get-RuleCounts }
```

### EXAMPLE 2
```
$data = Get-CachedValue -Key 'ExpensiveQuery' -Factory { Invoke-ExpensiveOperation } -ForceRefresh
```

## PARAMETERS

### -Key
Unique identifier for the cached item.

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

### -MaxAgeSeconds
Maximum age in seconds before the cached value expires.
Default is 300 (5 minutes).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 300
Accept pipeline input: False
Accept wildcard characters: False
```

### -Factory
Script block to execute if cache miss occurs.
The result is cached.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForceRefresh
If specified, ignores cached value and always executes the factory.

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

### The cached or newly created value.
## NOTES

## RELATED LINKS
