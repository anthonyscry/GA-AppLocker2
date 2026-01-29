---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-BatchPreview

## SYNOPSIS
Previews what would be created by batch generation without actually creating rules.

## SYNTAX

```
Get-BatchPreview [-Artifacts] <Array> [[-Mode] <String>] [-SkipDlls] [-SkipUnsigned] [-SkipScripts]
 [[-DedupeMode] <String>] [[-PublisherLevel] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns statistics about what rules would be generated, useful for the wizard preview step.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Artifacts
Array of artifacts to analyze.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Mode
Rule generation mode.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Smart
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipDlls
Exclude DLLs from preview.

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

### -SkipUnsigned
Exclude unsigned from preview.

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

### -SkipScripts
Exclude scripts from preview.

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

### -DedupeMode
Deduplication mode.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Smart
Accept pipeline input: False
Accept wildcard characters: False
```

### -PublisherLevel
{{ Fill PublisherLevel Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: PublisherProduct
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
