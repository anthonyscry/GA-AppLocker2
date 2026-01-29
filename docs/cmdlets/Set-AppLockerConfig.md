---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-AppLockerConfig

## SYNOPSIS
Updates GA-AppLocker configuration settings.

## SYNTAX

### SingleKey
```
Set-AppLockerConfig -Key <String> -Value <Object> [<CommonParameters>]
```

### Bulk
```
Set-AppLockerConfig -Settings <Hashtable> [<CommonParameters>]
```

## DESCRIPTION
Saves configuration settings to the settings.json file.
Can update a single key or merge an entire settings hashtable.

## EXAMPLES

### EXAMPLE 1
```
Set-AppLockerConfig -Key 'ScanTimeoutSeconds' -Value 600
```

Updates a single configuration value.

### EXAMPLE 2
```
Set-AppLockerConfig -Settings @{ MaxConcurrentScans = 20; AutoSaveArtifacts = $false }
```

Updates multiple configuration values at once.

## PARAMETERS

### -Key
The configuration key to update.

```yaml
Type: String
Parameter Sets: SingleKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The value to set for the specified key.

```yaml
Type: Object
Parameter Sets: SingleKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Settings
A hashtable of settings to merge with existing configuration.

```yaml
Type: Hashtable
Parameter Sets: Bulk
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result object with Success, Data, and Error properties.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
