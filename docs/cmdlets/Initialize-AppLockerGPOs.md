---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Initialize-AppLockerGPOs

## SYNOPSIS
Creates the default AppLocker GPOs for DC, Servers, and Workstations.

## SYNTAX

```
Initialize-AppLockerGPOs [-CreateOnly] [[-ServersOU] <String>] [[-WorkstationsOU] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates three GPOs:
- AppLocker-DC: Linked to Domain Controllers OU
- AppLocker-Servers: Linked to Servers OU
- AppLocker-Workstations: Linked to Computers OU

## EXAMPLES

### EXAMPLE 1
```
Initialize-AppLockerGPOs
```

Creates and links all three AppLocker GPOs.

## PARAMETERS

### -CreateOnly
Only create GPOs without linking them.

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

### -ServersOU
{{ Fill ServersOU Description }}

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

### -WorkstationsOU
{{ Fill WorkstationsOU Description }}

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

### [PSCustomObject] Result with Success, Data, and Error properties.
## NOTES

## RELATED LINKS
