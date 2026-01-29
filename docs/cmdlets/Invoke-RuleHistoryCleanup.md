---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Invoke-RuleHistoryCleanup

## SYNOPSIS
Cleans up old rule history, keeping only recent versions.

## SYNTAX

```
Invoke-RuleHistoryCleanup [[-KeepVersions] <Int32>] [[-OlderThanDays] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Cleans up old rule history, keeping only recent versions.
Executes the operation and returns a result object.

## EXAMPLES

### EXAMPLE 1
```
Invoke-RuleHistoryCleanup -KeepVersions 5 -OlderThanDays 30
```

## PARAMETERS

### -KeepVersions
Number of versions to keep per rule.
Default: 10.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -OlderThanDays
Delete versions older than this many days.
Default: 90.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 90
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
