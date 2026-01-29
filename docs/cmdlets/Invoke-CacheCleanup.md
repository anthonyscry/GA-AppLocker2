---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Invoke-CacheCleanup

## SYNOPSIS
Removes expired entries from cache.

## SYNTAX

```
Invoke-CacheCleanup [<CommonParameters>]
```

## DESCRIPTION
Scans the cache and removes all entries that have exceeded their TTL.
Useful for periodic maintenance.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CacheCleanup
```

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [int] Number of expired entries removed
## NOTES

## RELATED LINKS
