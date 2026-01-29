---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-ValidValues

## SYNOPSIS
Gets the list of valid values for a domain type.

## SYNTAX

```
Get-ValidValues [-Type] <String> [<CommonParameters>]
```

## DESCRIPTION
Gets the list of valid values for a domain type.
Returns the requested data in a standard result object.

## EXAMPLES

### EXAMPLE 1
```
Get-ValidValues -Type 'CollectionType'
```

## PARAMETERS

### -Type
The type to get valid values for.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [string[]] Array of valid values
## NOTES

## RELATED LINKS
