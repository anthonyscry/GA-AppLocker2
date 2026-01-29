---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Unregister-AppLockerEvent

## SYNOPSIS
Unregisters an event handler.

## SYNTAX

```
Unregister-AppLockerEvent [-EventName] <String> [[-HandlerId] <String>] [<CommonParameters>]
```

## DESCRIPTION
Removes a specific handler or all handlers for an event.

## EXAMPLES

### EXAMPLE 1
```
Unregister-AppLockerEvent -EventName 'RuleCreated' -HandlerId 'handler-123'
```

### EXAMPLE 2
```
Unregister-AppLockerEvent -EventName 'RuleCreated'
```

# Removes all handlers for RuleCreated

## PARAMETERS

### -EventName
Name of the event.

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

### -HandlerId
ID of the specific handler to remove.
If not specified, removes all handlers.

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

### [int] Number of handlers removed
## NOTES

## RELATED LINKS
