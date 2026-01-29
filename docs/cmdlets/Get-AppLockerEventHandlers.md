---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-AppLockerEventHandlers

## SYNOPSIS
Gets registered event handlers.

## SYNTAX

```
Get-AppLockerEventHandlers [[-EventName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns information about registered handlers for debugging and monitoring.

## EXAMPLES

### EXAMPLE 1
```
Get-AppLockerEventHandlers
```

### EXAMPLE 2
```
Get-AppLockerEventHandlers -EventName 'RuleCreated'
```

## PARAMETERS

### -EventName
Optional event name to filter.
Returns all handlers if not specified.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject[]] Handler information
## NOTES

## RELATED LINKS
