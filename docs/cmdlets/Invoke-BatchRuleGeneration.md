---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Invoke-BatchRuleGeneration

## SYNOPSIS
High-performance batch rule generation from artifacts.

## SYNTAX

```
Invoke-BatchRuleGeneration [-Artifacts] <Array> [[-Mode] <String>] [[-Action] <String>] [[-Status] <String>]
 [[-PublisherLevel] <String>] [[-UserOrGroupSid] <String>] [-SkipDlls] [-SkipUnsigned] [-SkipScripts]
 [-SkipJsOnly] [[-DedupeMode] <String>] [[-UnsignedMode] <String>] [[-CollectionName] <String>]
 [[-OnProgress] <ScriptBlock>] [<CommonParameters>]
```

## DESCRIPTION
Converts artifacts to AppLocker rules using an optimized pipeline:
1.
Pre-filter (exclusions) - O(n)
2.
Deduplicate in memory - O(n)
3.
Check existing rules (single index lookup) - O(1)
4.
Generate rule objects in memory (no disk I/O) - O(n)
5.
Bulk write all rules at once - Single I/O operation
6.
Single index rebuild

This is 10x+ faster than the sequential ConvertFrom-Artifact approach.

## EXAMPLES

### EXAMPLE 1
```
$result = Invoke-BatchRuleGeneration -Artifacts $scanResult.Data.Artifacts -SkipDlls -OnProgress {
```

param($pct, $msg)
    Write-Host "$pct% - $msg"
}

## PARAMETERS

### -Artifacts
Array of artifact objects from scanning module.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Mode
Rule type preference: Smart, Publisher, Hash, Path.
Smart = Publisher for signed, Hash for unsigned.

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

### -Action
Rule action: Allow or Deny.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Allow
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Initial rule status: Pending, Approved, Rejected, Review.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Pending
Accept pipeline input: False
Accept wildcard characters: False
```

### -PublisherLevel
Granularity for publisher rules: PublisherOnly, PublisherProduct, PublisherProductFile, Exact.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: PublisherProduct
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

### -SkipDlls
Exclude DLL artifacts from rule generation.

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
Exclude unsigned artifacts (requires hash rules).

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
Exclude script artifacts (PS1, BAT, CMD, VBS, JS).

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

### -SkipJsOnly
{{ Fill SkipJsOnly Description }}

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
Deduplication strategy: Smart, Publisher, Hash, None.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: Smart
Accept pipeline input: False
Accept wildcard characters: False
```

### -UnsignedMode
{{ Fill UnsignedMode Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: Hash
Accept pipeline input: False
Accept wildcard characters: False
```

### -CollectionName
{{ Fill CollectionName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnProgress
Scriptblock callback for progress updates.
Receives (percent, message).

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] with Success, RulesCreated, Skipped, Duplicates, Errors, Duration.
## NOTES

## RELATED LINKS
