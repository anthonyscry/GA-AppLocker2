---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Compare-Policies

## SYNOPSIS
Functions for comparing AppLocker policies and detecting differences.

## SYNTAX

```
Compare-Policies [[-SourcePolicyId] <String>] [[-TargetPolicyId] <String>] [[-SourcePolicy] <PSObject>]
 [[-TargetPolicy] <PSObject>] [-IncludeUnchanged] [<CommonParameters>]
```

## DESCRIPTION
Provides functions to compare two policies and identify added, removed, and modified rules.
Useful for reviewing changes before deployment or auditing policy drift.

## EXAMPLES

### EXAMPLE 1
```
Compare-Policies
```

# Compare Policies

## PARAMETERS

### -SourcePolicyId
{{ Fill SourcePolicyId Description }}

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

### -TargetPolicyId
{{ Fill TargetPolicyId Description }}

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

### -SourcePolicy
{{ Fill SourcePolicy Description }}

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetPolicy
{{ Fill TargetPolicy Description }}

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeUnchanged
{{ Fill IncludeUnchanged Description }}

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

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
