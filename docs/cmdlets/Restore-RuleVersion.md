---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Restore-RuleVersion

## SYNOPSIS
Restores a rule to a previous version.

## SYNTAX

```
Restore-RuleVersion [-RuleId] <String> [-Version] <Int32> [<CommonParameters>]
```

## DESCRIPTION
Restores a rule to a previous version.
Restores from a previously saved version.

## EXAMPLES

### EXAMPLE 1
```
Restore-RuleVersion -RuleId '12345678-...' -Version 2
```

## PARAMETERS

### -RuleId
The rule ID to restore.

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

### -Version
The version number to restore to.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: 0
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
