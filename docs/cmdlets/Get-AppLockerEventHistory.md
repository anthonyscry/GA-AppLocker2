---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-AppLockerEventHistory

## SYNOPSIS
Gets event history.

## SYNTAX

```
Get-AppLockerEventHistory [[-Last] <Int32>] [[-EventName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns recent event publications for debugging.

## EXAMPLES

### EXAMPLE 1
```
Get-AppLockerEventHistory -Last 10
```

### EXAMPLE 2
```
Get-AppLockerEventHistory -EventName 'RuleCreated'
```

## PARAMETERS

### -Last
Number of recent events to return.
Default is 20.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 20
Accept pipeline input: False
Accept wildcard characters: False
```

### -EventName
Optional filter by event name.

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

### [PSCustomObject[]] Event history records
## NOTES

## RELATED LINKS
