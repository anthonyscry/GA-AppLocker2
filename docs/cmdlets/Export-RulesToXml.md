---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Export-RulesToXml

## SYNOPSIS
Exports rules to AppLocker XML format.

## SYNTAX

```
Export-RulesToXml [-OutputPath] <String> [-IncludeAllStatuses] [[-CollectionTypes] <String[]>]
 [[-EnforcementMode] <String>] [<CommonParameters>]
```

## DESCRIPTION
Exports approved rules to XML format compatible with AppLocker GPO import.
Only exports rules with Approved status by default.

## EXAMPLES

### EXAMPLE 1
```
Export-RulesToXml -OutputPath 'C:\Policies\applocker.xml'
```

### EXAMPLE 2
```
Export-RulesToXml -OutputPath 'C:\Policies\exe-rules.xml' -CollectionTypes 'Exe' -EnforcementMode Enabled
```

## PARAMETERS

### -OutputPath
Path for the output XML file.

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

### -IncludeAllStatuses
Include rules regardless of status (not just Approved).

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

### -CollectionTypes
Specific collections to export.
Default is all.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @('Exe', 'Dll', 'Msi', 'Script', 'Appx')
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnforcementMode
Enforcement mode for each collection: NotConfigured, AuditOnly, Enabled.
Default is AuditOnly for safety.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: AuditOnly
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success and path to exported file.
## NOTES

## RELATED LINKS
