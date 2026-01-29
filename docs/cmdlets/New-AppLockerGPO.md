---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-AppLockerGPO

## SYNOPSIS
Creates a new GPO for AppLocker policies.

## SYNTAX

```
New-AppLockerGPO [-GPOName] <String> [[-Comment] <String>] [<CommonParameters>]
```

## DESCRIPTION
Creates a new GPO for AppLocker policies.

## EXAMPLES

### EXAMPLE 1
```
New-AppLockerGPO -GPOName "AppLocker-Workstations"
```

## PARAMETERS

### -GPOName
The name for the new GPO.

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

### -Comment
Optional comment/description for the GPO.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Created by GA-AppLocker Dashboard
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
