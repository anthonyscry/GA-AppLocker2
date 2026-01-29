---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Export-ScanResults

## SYNOPSIS
Exports scan results to CSV or JSON.

## SYNTAX

```
Export-ScanResults [-ScanId] <String> [-OutputPath] <String> [[-Format] <String>] [<CommonParameters>]
```

## DESCRIPTION
Exports artifact data from a scan to external formats.

## EXAMPLES

### EXAMPLE 1
```
Export-ScanResults -ScanId '12345...' -OutputPath 'C:\Reports\scan.csv' -Format CSV
```

## PARAMETERS

### -ScanId
ID of scan to export.

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

### -OutputPath
Destination file path.

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

### -Format
Output format: CSV or JSON.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
