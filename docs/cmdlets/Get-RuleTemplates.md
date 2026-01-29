---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-RuleTemplates

## SYNOPSIS
Gets all available rule templates.

## SYNTAX

```
Get-RuleTemplates [[-TemplateName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Loads and returns all rule templates from the RuleTemplates.json file.
Each template contains pre-configured rules for common applications.

## EXAMPLES

### EXAMPLE 1
```
Get-RuleTemplates
```

Returns all available rule templates.

### EXAMPLE 2
```
Get-RuleTemplates -TemplateName 'Microsoft Office'
```

Returns only the Microsoft Office template.

## PARAMETERS

### -TemplateName
Optional.
Filter to return only a specific template by name.

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

### [PSCustomObject] Template data with Success, Data, and Error properties.
## NOTES

## RELATED LINKS
