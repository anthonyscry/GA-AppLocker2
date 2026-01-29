---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-AppLockerConfig

## SYNOPSIS
Retrieves the GA-AppLocker configuration settings.

## SYNTAX

```
Get-AppLockerConfig [[-Key] <String>] [<CommonParameters>]
```

## DESCRIPTION
Loads configuration from the settings.json file in the application
data directory.
Returns default values if config file doesn't exist.

## EXAMPLES

### EXAMPLE 1
```
$config = Get-AppLockerConfig
```

Returns all configuration settings as a hashtable.

### EXAMPLE 2
```
$timeout = Get-AppLockerConfig -Key 'ScanTimeoutSeconds'
```

Returns the value of a specific configuration key.

## PARAMETERS

### -Key
Optional.
Retrieve a specific configuration key instead of all settings.

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

### [hashtable] or [object] Configuration settings or specific value.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
