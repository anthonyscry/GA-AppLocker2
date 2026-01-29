---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Restore-SessionState

## SYNOPSIS
Restores the application session state from a saved file.

## SYNTAX

```
Restore-SessionState [-Force] [[-ExpiryDays] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Loads previously saved session state including discovered machines,
scan artifacts, selected items, and UI state.
Automatically ignores
sessions older than 7 days unless Force is specified.

## EXAMPLES

### EXAMPLE 1
```
$session = Restore-SessionState
```

if ($session.Success) {
    $machines = $session.Data.discoveredMachines
}

### EXAMPLE 2
```
$session = Restore-SessionState -Force -ExpiryDays 30
```

## PARAMETERS

### -Force
Restore session even if it's older than the expiry threshold.

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

### -ExpiryDays
Number of days after which a session is considered expired.
Default is 7.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 7
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success and Data (session state) properties.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
