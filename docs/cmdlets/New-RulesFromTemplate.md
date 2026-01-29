---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-RulesFromTemplate

## SYNOPSIS
Creates AppLocker rules from a template.

## SYNTAX

```
New-RulesFromTemplate [-TemplateName] <String> [[-UserOrGroupSid] <String>] [[-Status] <String>] [-Save]
 [<CommonParameters>]
```

## DESCRIPTION
Creates rules from a named template.
Templates provide pre-configured
rules for common enterprise applications.

## EXAMPLES

### EXAMPLE 1
```
New-RulesFromTemplate -TemplateName 'Microsoft Office'
```

Creates Office rules with default settings.

### EXAMPLE 2
```
New-RulesFromTemplate -TemplateName 'Block High Risk Locations' -Status Approved -Save
```

Creates and saves pre-approved deny rules for risky paths.

## PARAMETERS

### -TemplateName
Name of the template to use (e.g., 'Microsoft Office', 'Google Chrome').

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

### -UserOrGroupSid
Optional.
Override the default user/group SID for all rules.
Default is Everyone (S-1-1-0).

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

### -Status
Status for created rules: Pending, Approved, Rejected, Review.
Default is Pending.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Pending
Accept pipeline input: False
Accept wildcard characters: False
```

### -Save
If specified, saves the rules to disk.

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

### [PSCustomObject] Created rules with Success, Data, and Error properties.
## NOTES

## RELATED LINKS
