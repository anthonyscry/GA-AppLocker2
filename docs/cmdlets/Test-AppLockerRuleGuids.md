---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-AppLockerRuleGuids

## SYNOPSIS
Validates all rule GUIDs in an AppLocker policy.

## SYNTAX

```
Test-AppLockerRuleGuids [-XmlPath] <String> [<CommonParameters>]
```

## DESCRIPTION
Ensures all rule IDs are:
- Valid GUID format (8-4-4-4-12)
- Uppercase (AppLocker requirement)
- Unique across all rule collections

## EXAMPLES

### EXAMPLE 1
```
Test-AppLockerRuleGuids -XmlPath "C:\Policies\baseline.xml"
```

## PARAMETERS

### -XmlPath
Path to the AppLocker policy XML file.

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

### [PSCustomObject] with Success, Errors, DuplicateGuids, TotalGuids, UniqueGuids properties
## NOTES

## RELATED LINKS
