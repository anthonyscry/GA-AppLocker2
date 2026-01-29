---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-CachedValue

## SYNOPSIS
Sets a value in the cache with optional TTL.

## SYNTAX

```
Set-CachedValue [-Key] <String> [-Value] <Object> [[-TTLSeconds] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Stores a value in the cache with metadata for expiration tracking.

## EXAMPLES

### EXAMPLE 1
```
Set-CachedValue -Key 'UserPrefs' -Value $prefs -TTLSeconds 3600
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

### -Value
The value to cache.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TTLSeconds
Time-to-live in seconds.
Default is 300 (5 minutes).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 300
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None
## NOTES

## RELATED LINKS
