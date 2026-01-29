---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-AppLockerEventLogs

## SYNOPSIS
Collects AppLocker event logs from local or remote machines.

## SYNTAX

```
Get-AppLockerEventLogs [[-ComputerName] <String>] [[-Credential] <PSCredential>] [[-StartTime] <DateTime>]
 [[-MaxEvents] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves AppLocker-related events (Event IDs 8001-8025) from the
Microsoft-Windows-AppLocker operational logs.

Event ID Reference:
- 8001: EXE/DLL allowed
- 8002: EXE/DLL would be blocked (audit mode)
- 8003: EXE/DLL blocked
- 8004: EXE/DLL blocked (no rule)
- 8005: Script allowed
- 8006: Script would be blocked (audit mode)
- 8007: Script blocked
- 8020: Packaged app allowed
- 8021: Packaged app would be blocked
- 8022: Packaged app blocked
- 8023: MSI/MSP allowed
- 8024: MSI/MSP would be blocked
- 8025: MSI/MSP blocked

## EXAMPLES

### EXAMPLE 1
```
Get-AppLockerEventLogs
```

### EXAMPLE 2
```
Get-AppLockerEventLogs -ComputerName 'Server01' -StartTime (Get-Date).AddDays(-7)
```

## PARAMETERS

### -ComputerName
Target computer.
Defaults to local machine.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $env:COMPUTERNAME
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
PSCredential for remote access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
Only collect events after this time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxEvents
Maximum number of events to collect per log.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, Data (events array), and Summary.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
