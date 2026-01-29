---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Write-AuditLog

## SYNOPSIS
Writes an entry to the audit trail.

## SYNTAX

```
Write-AuditLog [-Action] <String> [-Category] <String> [[-Target] <String>] [[-TargetId] <String>]
 [[-Details] <String>] [[-OldValue] <String>] [[-NewValue] <String>] [<CommonParameters>]
```

## DESCRIPTION
Writes an entry to the audit trail.
Writes a timestamped entry to the log.

## EXAMPLES

### EXAMPLE 1
```
Write-AuditLog -Action 'RuleApproved' -Category 'Rule' -Target 'Microsoft Office' -TargetId 'rule-123'
```

## PARAMETERS

### -Action
The action performed (e.g., 'RuleApproved', 'PolicyDeployed').

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

### -Category
Category of action: Rule, Policy, Scan, Machine, Credential, System.

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

### -Target
The target object (rule name, policy name, machine name, etc.).

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

### -TargetId
The unique ID of the target object.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Details
Additional details about the action.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OldValue
Previous value (for changes).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewValue
New value (for changes).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
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
