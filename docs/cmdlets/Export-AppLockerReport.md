---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Export-AppLockerReport

## SYNOPSIS
Exports a comprehensive HTML report of AppLocker data.

## SYNTAX

```
Export-AppLockerReport [-OutputPath] <String> [-IncludeRules] [-IncludePolicies] [-IncludeAuditLog]
 [[-AuditDays] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Exports a comprehensive HTML report of AppLocker data.
Writes output to the specified path.

## EXAMPLES

### EXAMPLE 1
```
Export-AppLockerReport -OutputPath 'C:\Reports\applocker-report.html'
```

## PARAMETERS

### -OutputPath
Path to save the HTML report.

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

### -IncludeRules
Include rules section.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludePolicies
Include policies section.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeAuditLog
Include recent audit log.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuditDays
Number of days of audit history to include.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
