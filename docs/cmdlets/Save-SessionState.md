---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Save-SessionState

## SYNOPSIS
Saves the current application session state to a file.

## SYNTAX

```
Save-SessionState [-State] <Hashtable> [-Force] [<CommonParameters>]
```

## DESCRIPTION
Persists the current application state including discovered machines,
scan artifacts, selected items, and UI state to enable session restoration
on next app launch.
Automatically expires old sessions after 7 days.

## EXAMPLES

### EXAMPLE 1
```
Save-SessionState -State @{ discoveredMachines = @('PC001', 'PC002') }
```

## PARAMETERS

### -State
Hashtable containing the session state to save.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrite existing session file without checking expiry.

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

### [PSCustomObject] Result with Success and Data properties.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
