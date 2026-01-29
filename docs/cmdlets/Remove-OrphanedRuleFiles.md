---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Remove-OrphanedRuleFiles

## SYNOPSIS
Removes rule files that are not in the index.

## SYNTAX

```
Remove-OrphanedRuleFiles [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Scans the Rules directory for JSON files that don't have a corresponding
entry in the rules index.
These orphaned files take up disk space and
can slow down directory operations.

## EXAMPLES

### EXAMPLE 1
```
Remove-OrphanedRuleFiles -WhatIf
```

# Shows orphaned files without deleting

### EXAMPLE 2
```
Remove-OrphanedRuleFiles -Force
```

# Deletes orphaned files without prompting

## PARAMETERS

### -Force
Skip confirmation prompt.

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
Show what would be deleted without actually deleting.

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

### [PSCustomObject] Result with count of files removed.
## NOTES

## RELATED LINKS
