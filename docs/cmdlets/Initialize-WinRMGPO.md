---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Initialize-WinRMGPO

## SYNOPSIS
Creates and configures the WinRM GPO for remote management.

## SYNTAX

```
Initialize-WinRMGPO [[-GPOName] <String>] [-LinkToRoot] [<CommonParameters>]
```

## DESCRIPTION
Creates a GPO named 'AppLocker-EnableWinRM' that:
- Enables the WinRM service
- Configures WinRM to start automatically
- Enables firewall rules for WinRM (HTTP/HTTPS)
- Links to domain root (all computers)

## EXAMPLES

### EXAMPLE 1
```
Initialize-WinRMGPO
```

Creates the WinRM GPO with default settings.

## PARAMETERS

### -GPOName
Name of the GPO to create.
Default is 'AppLocker-EnableWinRM'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: AppLocker-EnableWinRM
Accept pipeline input: False
Accept wildcard characters: False
```

### -LinkToRoot
Link the GPO to domain root.
Default is $true.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, Data, and Error properties.
## NOTES

## RELATED LINKS
