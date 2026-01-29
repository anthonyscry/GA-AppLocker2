---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-Policy

## SYNOPSIS
Creates a new AppLocker policy.

## SYNTAX

```
New-Policy [-Name] <String> [[-Description] <String>] [[-EnforcementMode] <String>] [[-Phase] <Int32>]
 [[-RuleIds] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Creates a policy that can contain multiple rules and be
targeted to specific OUs or GPOs.
Supports phase-based
deployment with automatic rule type filtering.

## EXAMPLES

### EXAMPLE 1
```
New-Policy -Name "Baseline Policy" -Phase 1
```

Creates a Phase 1 policy (EXE only, AuditOnly mode)

### EXAMPLE 2
```
New-Policy -Name "Production Policy" -Phase 4
```

Creates a Phase 4 policy (all rules, Enabled mode)

## PARAMETERS

### -Name
The name of the policy.

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

### -Description
Optional description of the policy.

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

### -EnforcementMode
The enforcement mode: NotConfigured, AuditOnly, or Enabled.
Note: When using Phase parameter, enforcement is auto-set:
- Phase 1-3: AuditOnly
- Phase 4: Enabled

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: AuditOnly
Accept pipeline input: False
Accept wildcard characters: False
```

### -Phase
The deployment phase (1-4).
Controls which rule types are exported:
- Phase 1: EXE rules only (AuditOnly) - Initial testing
- Phase 2: EXE + Script rules (AuditOnly)
- Phase 3: EXE + Script + MSI rules (AuditOnly)
- Phase 4: All rules including DLL (Enabled) - Full enforcement

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -RuleIds
Optional array of rule IDs to include in the policy.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
