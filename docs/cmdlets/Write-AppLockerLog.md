---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Write-AppLockerLog

## SYNOPSIS
Writes a log entry to the GA-AppLocker log file and optionally to console.

## SYNTAX

```
Write-AppLockerLog [-Message] <String> [-Level <String>] [-NoConsole] [<CommonParameters>]
```

## DESCRIPTION
Centralized logging function for all GA-AppLocker operations.
Writes timestamped entries to a daily log file with configurable
log levels (Info, Warning, Error, Debug).

## EXAMPLES

### EXAMPLE 1
```
Write-AppLockerLog -Message "Scan started for DC01"
```

Writes an Info-level log entry.

### EXAMPLE 2
```
Write-AppLockerLog -Level Error -Message "WinRM connection failed"
```

Writes an Error-level log entry.

## PARAMETERS

### -Message
The log message to write.

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

### -Level
The severity level of the log entry.
Valid values: Info, Warning, Error, Debug.
Default: Info

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Info
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoConsole
Suppress console output.
Log file is always written.

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

### None. Writes to log file and optionally console.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0
Requires: PowerShell 5.1+

## RELATED LINKS
