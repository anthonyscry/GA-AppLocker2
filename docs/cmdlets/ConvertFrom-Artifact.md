---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# ConvertFrom-Artifact

## SYNOPSIS
Converts artifacts to AppLocker rules.

## SYNTAX

```
ConvertFrom-Artifact [-Artifact] <PSObject[]> [[-PreferredRuleType] <String>] [-GroupByPublisher]
 [-IncludeProductVersion] [[-PublisherLevel] <String>] [[-Action] <String>] [[-Status] <String>]
 [[-UserOrGroupSid] <String>] [-Save] [<CommonParameters>]
```

## DESCRIPTION
Automatically generates AppLocker rules from scanned artifacts.
Uses a smart strategy to select the best rule type:
- Publisher rule if artifact is signed (preferred)
- Hash rule if artifact is unsigned
- Path rule if explicitly requested

## EXAMPLES

### EXAMPLE 1
```
$artifacts | ConvertFrom-Artifact -Save
```

Converts all artifacts to rules and saves them.

### EXAMPLE 2
```
ConvertFrom-Artifact -Artifact $myArtifact -PreferredRuleType Hash -Save
```

Forces hash rule generation regardless of signature status.

### EXAMPLE 3
```
$scanResult.Data.Artifacts | ConvertFrom-Artifact -GroupByPublisher -Status Approved -Save
```

Groups signed artifacts by publisher and auto-approves them.

## PARAMETERS

### -Artifact
Artifact object from scanning module (or array of artifacts).

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PreferredRuleType
Force a specific rule type: Auto, Publisher, Hash, Path.
Default is Auto (publisher for signed, hash for unsigned).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Auto
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupByPublisher
Group artifacts by publisher into single rules (default: true).
Only applies to publisher rules.

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

### -IncludeProductVersion
Include product version constraints in publisher rules.

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

### -PublisherLevel
{{ Fill PublisherLevel Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: PublisherProduct
Accept pipeline input: False
Accept wildcard characters: False
```

### -Action
Rule action: Allow or Deny.
Default is Allow.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Allow
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Initial rule status: Pending, Approved, Rejected, Review.
Default is Pending for review workflow.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Pending
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserOrGroupSid
{{ Fill UserOrGroupSid Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: S-1-1-0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Save
Save rules to storage immediately.

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

### [PSCustomObject] Result with Success, Data (array of rules), and Summary.
## NOTES

## RELATED LINKS
