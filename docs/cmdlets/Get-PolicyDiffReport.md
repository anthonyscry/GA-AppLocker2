---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-PolicyDiffReport

## SYNOPSIS
Generates a human-readable diff report between two policies.

## SYNTAX

```
Get-PolicyDiffReport [-SourcePolicyId] <String> [-TargetPolicyId] <String> [[-Format] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a formatted text report showing all differences between policies.
Useful for review meetings or audit documentation.

## EXAMPLES

### EXAMPLE 1
```
Get-PolicyDiffReport -SourcePolicyId "abc123" -TargetPolicyId "def456"
```

### EXAMPLE 2
```
Get-PolicyDiffReport -SourcePolicyId "abc123" -TargetPolicyId "def456" -Format Markdown
```

## PARAMETERS

### -SourcePolicyId
The ID of the source/baseline policy.

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

### -TargetPolicyId
The ID of the target/comparison policy.

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
Output format: Text, Html, or Markdown.
Default is Text.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Text
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Report with Success, Data (formatted string), and Error.
## NOTES

## RELATED LINKS
