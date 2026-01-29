---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Approve-TrustedVendorRules

## SYNOPSIS
Approves all rules from trusted vendors.

## SYNTAX

```
Approve-TrustedVendorRules [-IncludeMediumRisk] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Convenience function to bulk-approve rules from well-known trusted vendors
like Microsoft, Adobe, Oracle, Google, etc.
Only approves rules currently
in Pending status.

## EXAMPLES

### EXAMPLE 1
```
Approve-TrustedVendorRules -WhatIf
```

Shows how many rules would be approved without making changes.

### EXAMPLE 2
```
Approve-TrustedVendorRules
```

Approves all pending rules from trusted vendors.

## PARAMETERS

### -IncludeMediumRisk
Also approve medium-risk vendors (NodeJS, Python runtimes).

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

### [PSCustomObject] Combined result from all vendor approvals.
## NOTES

## RELATED LINKS
