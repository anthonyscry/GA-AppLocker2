---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Save-RuleVersion

## SYNOPSIS
Saves a new version of a rule to history.

## SYNTAX

```
Save-RuleVersion [-Rule] <PSObject> [-ChangeType] <String> [[-ChangeSummary] <String>] [<CommonParameters>]
```

## DESCRIPTION
Saves a new version of a rule to history.
Writes data to persistent storage.

## EXAMPLES

### EXAMPLE 1
```
Save-RuleVersion -Rule $rule -ChangeType 'Updated' -ChangeSummary 'Changed version range'
```

## PARAMETERS

### -Rule
The rule object to save.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChangeType
Type of change: Created, Updated, StatusChanged, Restored.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChangeSummary
Brief description of the change.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
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
