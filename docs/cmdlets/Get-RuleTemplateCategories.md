---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-RuleTemplateCategories

## SYNOPSIS
Gets template names grouped by category.

## SYNTAX

```
Get-RuleTemplateCategories [<CommonParameters>]
```

## DESCRIPTION
Returns templates organized by their purpose: Allow (applications),
Block (deny rules), and Windows (system defaults).

## EXAMPLES

### EXAMPLE 1
```
Get-RuleTemplateCategories
```

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Categories with template names.
## NOTES

## RELATED LINKS
