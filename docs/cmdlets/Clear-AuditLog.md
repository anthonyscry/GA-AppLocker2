---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Clear-AuditLog

## SYNOPSIS
Clears audit log entries older than specified days.

## SYNTAX

```
Clear-AuditLog [-DaysToKeep] <Int32> [<CommonParameters>]
```

## DESCRIPTION
Clears audit log entries older than specified days.
Removes all matching items.

## EXAMPLES

### EXAMPLE 1
```
Clear-AuditLog -DaysToKeep 90
```

## PARAMETERS

### -DaysToKeep
Number of days of entries to keep.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
