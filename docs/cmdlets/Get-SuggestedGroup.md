---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-SuggestedGroup

## SYNOPSIS
Suggests a group name for an artifact or rule based on vendor and product patterns.

## SYNTAX

```
Get-SuggestedGroup [[-PublisherName] <String>] [[-ProductName] <String>] [[-FilePath] <String>]
 [[-IsSigned] <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Analyzes publisher certificate, product name, and file path to suggest
an appropriate grouping for AppLocker rules.
Uses a database of known
vendors and product categories to provide intelligent suggestions.

This enables:
- Automatic rule organization by vendor/category
- Risk-based categorization (Low/Medium/High)
- Consistent naming across the enterprise

## EXAMPLES

### EXAMPLE 1
```
Get-SuggestedGroup -PublisherName 'O=MICROSOFT CORPORATION' -ProductName 'Microsoft Office Word'
```

Returns: @{ Vendor = 'Microsoft'; Category = 'Office'; SuggestedGroup = 'Microsoft-Office'; RiskLevel = 'Low' }

### EXAMPLE 2
```
Get-SuggestedGroup -FilePath 'C:\Windows\System32\notepad.exe'
```

Returns suggestion based on path analysis.

## PARAMETERS

### -PublisherName
The publisher certificate subject (e.g., 'O=MICROSOFT CORPORATION').

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProductName
The product name from file metadata.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath
The full file path of the artifact.

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

### -IsSigned
Whether the file is digitally signed.
Default assumes signed if PublisherName provided.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, Data containing suggestion details.
## NOTES

## RELATED LINKS
