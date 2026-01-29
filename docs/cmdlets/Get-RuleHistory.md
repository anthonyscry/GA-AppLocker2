---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-RuleHistory

## SYNOPSIS
Functions for rule history and versioning.

## SYNTAX

```
Get-RuleHistory [-RuleId] <String> [-IncludeContent] [<CommonParameters>]
```

## DESCRIPTION
Provides version tracking for rule changes including:
- Automatic version history on rule updates
- View previous versions
- Restore from previous version
- Compare versions

## EXAMPLES

### EXAMPLE 1
```
Get-RuleHistory
```

# Get RuleHistory

## PARAMETERS

### -RuleId
{{ Fill RuleId Description }}

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

### -IncludeContent
{{ Fill IncludeContent Description }}

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

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
