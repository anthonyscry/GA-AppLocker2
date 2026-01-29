---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Register-AppLockerEvent

## SYNOPSIS
Registers an event handler.

## SYNTAX

```
Register-AppLockerEvent [-EventName] <String> [-Handler] <ScriptBlock> [[-HandlerId] <String>]
 [[-Priority] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Subscribes a script block to be executed when a specific event is published.
Multiple handlers can be registered for the same event.

## EXAMPLES

### EXAMPLE 1
```
Register-AppLockerEvent -EventName 'RuleCreated' -Handler {
```

param($EventData)
    Write-Host "Rule created: $($EventData.RuleId)"
    Clear-AppLockerCache -Pattern 'Rule*'
}

### EXAMPLE 2
```
Register-AppLockerEvent -EventName 'ScanCompleted' -Handler { Update-DashboardStats } -Priority 10
```

## PARAMETERS

### -EventName
Name of the event to subscribe to.

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

### -Handler
Script block to execute when event is published.
Receives $EventData parameter.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HandlerId
Optional unique identifier for the handler.
Auto-generated if not provided.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: [guid]::NewGuid().ToString()
Accept pipeline input: False
Accept wildcard characters: False
```

### -Priority
Handler priority (lower = earlier execution).
Default is 100.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [string] The handler ID
## NOTES

## RELATED LINKS
