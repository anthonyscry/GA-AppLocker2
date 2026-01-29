---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Export-ForPowerBI

## SYNOPSIS
Exports data in formats optimized for Power BI.

## SYNTAX

```
Export-ForPowerBI [-OutputDirectory] <String> [-IncludeRules] [-IncludePolicies] [-IncludeAuditLog]
 [[-Format] <String>] [<CommonParameters>]
```

## DESCRIPTION
Exports data in formats optimized for Power BI.
Writes output to the specified path.

## EXAMPLES

### EXAMPLE 1
```
Export-ForPowerBI -OutputDirectory 'C:\PowerBI\Data' -Format CSV
```

## PARAMETERS

### -OutputDirectory
Directory to save the export files.

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

### -IncludeRules
Export rules data.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludePolicies
Export policies data.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeAuditLog
Export audit log data.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Format
Export format: CSV or JSON.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: CSV
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
