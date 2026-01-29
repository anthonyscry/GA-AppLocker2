---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-RuleIndexWatcherDebounce

## SYNOPSIS
Sets the debounce delay for index rebuilding.

## SYNTAX

```
Set-RuleIndexWatcherDebounce [-Milliseconds] <Int32> [<CommonParameters>]
```

## DESCRIPTION
Sets the debounce delay for index rebuilding.
Persists the change to the GA-AppLocker data store.

## EXAMPLES

### EXAMPLE 1
```
Set-RuleIndexWatcherDebounce -Milliseconds 5000
```

## PARAMETERS

### -Milliseconds
Delay in milliseconds to wait after the last file change before rebuilding.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
