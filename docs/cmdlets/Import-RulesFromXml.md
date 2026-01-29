---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Import-RulesFromXml

## SYNOPSIS
Imports rules from an AppLocker XML policy file.

## SYNTAX

```
Import-RulesFromXml [-Path] <String> [[-Status] <String>] [-SkipDuplicates] [<CommonParameters>]
```

## DESCRIPTION
Parses an AppLocker XML policy file and imports rules into the GA-AppLocker database.
Supports Publisher, Hash, and Path rules from Exe, Msi, Script, and Dll collections.

## EXAMPLES

### EXAMPLE 1
```
Import-RulesFromXml -Path 'C:\Policies\AppLocker.xml'
```

Imports all rules from the XML file with 'Pending' status.

### EXAMPLE 2
```
Import-RulesFromXml -Path 'C:\Policies\AppLocker.xml' -Status 'Approved' -SkipDuplicates
```

Imports rules as 'Approved' and skips any duplicates.

## PARAMETERS

### -Path
Path to the AppLocker XML file to import.

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

### -Status
Initial status for imported rules.
Defaults to 'Pending'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Pending
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipDuplicates
If specified, skips rules that already exist (by hash or publisher+product match).

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

## NOTES

## RELATED LINKS
