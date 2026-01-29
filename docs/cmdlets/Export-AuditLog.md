---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Export-AuditLog

## SYNOPSIS
Exports audit log to CSV or JSON file.

## SYNTAX

```
Export-AuditLog [-OutputPath] <String> [[-Format] <String>] [[-Category] <String>] [[-StartDate] <DateTime>]
 [[-EndDate] <DateTime>] [<CommonParameters>]
```

## DESCRIPTION
Exports audit log to CSV or JSON file.
Writes output to the specified path.

## EXAMPLES

### EXAMPLE 1
```
Export-AuditLog -OutputPath 'C:\AuditExport.csv' -Format CSV -StartDate (Get-Date).AddDays(-30)
```

## PARAMETERS

### -OutputPath
Path to save the export file.

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

### -Category
Filter by category before export.

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

### -StartDate
Filter entries from this date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndDate
Filter entries until this date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
