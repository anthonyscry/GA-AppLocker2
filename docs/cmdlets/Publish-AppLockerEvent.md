---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Publish-AppLockerEvent

## SYNOPSIS
Publishes an event to all registered handlers.

## SYNTAX

```
Publish-AppLockerEvent [-EventName] <String> [[-EventData] <Object>] [-Async] [<CommonParameters>]
```

## DESCRIPTION
Triggers all handlers registered for the specified event, passing
the event data to each handler.

## EXAMPLES

### EXAMPLE 1
```
Publish-AppLockerEvent -EventName 'RuleCreated' -EventData @{
```

RuleId = 'rule-123'
    RuleType = 'Hash'
    CreatedBy = 'User'
}

### EXAMPLE 2
```
Publish-AppLockerEvent -EventName 'ScanProgress' -EventData @{ Percent = 50 } -Async
```

## PARAMETERS

### -EventName
Name of the event to publish.

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

### -EventData
Data to pass to event handlers.
Can be any object.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Async
If specified, handlers are executed in background jobs (fire-and-forget).

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

### [PSCustomObject] Event result with handler execution status
## NOTES

## RELATED LINKS
