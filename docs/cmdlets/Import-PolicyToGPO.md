---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Import-PolicyToGPO

## SYNOPSIS
Imports an AppLocker policy XML to a GPO.

## SYNTAX

```
Import-PolicyToGPO [-GPOName] <String> [-XmlPath] <String> [-Merge] [<CommonParameters>]
```

## DESCRIPTION
Uses Set-AppLockerPolicy to import the XML policy
to the specified GPO.

## EXAMPLES

### EXAMPLE 1
```
Import-PolicyToGPO -GPOName "AppLocker-Workstations" -XmlPath "C:\policy.xml"
```

## PARAMETERS

### -GPOName
The name of the target GPO.

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

### -XmlPath
Path to the AppLocker policy XML file.

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

### -Merge
If true, merge with existing policy.
If false, replace.

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
