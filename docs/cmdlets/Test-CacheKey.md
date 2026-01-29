---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-CacheKey

## SYNOPSIS
Tests if a cache key exists and is valid.

## SYNTAX

```
Test-CacheKey [-Key] <String> [[-MaxAgeSeconds] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Checks if a key exists in cache and hasn't expired.

## EXAMPLES

### EXAMPLE 1
```
if (Test-CacheKey -Key 'RuleCounts') { ... }
```

## PARAMETERS

### -Key
The cache key to test.

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
Maximum age to consider valid.
Default is 300.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [bool] True if key exists and is valid
## NOTES

## RELATED LINKS
