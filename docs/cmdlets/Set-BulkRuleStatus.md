---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-BulkRuleStatus

## SYNOPSIS
Bulk update rule status for multiple rules.

## SYNTAX

```
Set-BulkRuleStatus [-Status] <String> [[-Vendor] <String>] [[-VendorPattern] <String>]
 [[-PublisherPattern] <String>] [[-GroupName] <String>] [[-RuleType] <String>] [[-CollectionType] <String>]
 [[-CurrentStatus] <String>] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Efficiently updates the status of multiple AppLocker rules based on filters.
Supports filtering by vendor, publisher pattern, group, rule type, and collection.
Essential for processing large numbers of pending rules.

## EXAMPLES

### EXAMPLE 1
```
Set-BulkRuleStatus -VendorPattern '*MICROSOFT*' -Status Approved -CurrentStatus Pending
```

Approves all pending Microsoft rules.

### EXAMPLE 2
```
Set-BulkRuleStatus -PublisherPattern '*ADOBE*' -Status Approved -WhatIf
```

Shows what Adobe rules would be approved without making changes.

## PARAMETERS

### -Status
New status to apply: Pending, Approved, Rejected, Review.

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

### -Vendor
Match rules where GroupVendor equals this value (exact match).

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

### -VendorPattern
Match rules where GroupVendor matches this wildcard pattern.

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

### -PublisherPattern
Match rules where PublisherName matches this wildcard pattern (Publisher rules only).

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

### -GroupName
Match rules where GroupName equals this value.

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

### -RuleType
Filter by rule type: Publisher, Hash, Path.

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

### -CollectionType
Filter by collection: Exe, Dll, Msi, Script, Appx.

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

### -CurrentStatus
Only update rules that currently have this status.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the updated rules.

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

### -WhatIf
Preview changes without applying them.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, UpdatedCount, and optionally Data.
## NOTES

## RELATED LINKS
