---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Update-Policy

## SYNOPSIS
Updates an existing AppLocker policy.

## SYNTAX

```
Update-Policy [-Id] <String> [[-EnforcementMode] <String>] [[-Phase] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Updates policy properties like enforcement mode and phase.

## EXAMPLES

### EXAMPLE 1
```
Update-Policy -Id "12345..." -EnforcementMode "Enabled" -Phase 4
```

## PARAMETERS

### -Id
The policy GUID to update.

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

### -EnforcementMode
The enforcement mode: NotConfigured, AuditOnly, or Enabled.

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

### -Phase
The deployment phase (1-4).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
