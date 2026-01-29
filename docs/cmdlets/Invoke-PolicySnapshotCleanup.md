---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Invoke-PolicySnapshotCleanup

## SYNOPSIS
Removes old snapshots based on retention policy.

## SYNTAX

```
Invoke-PolicySnapshotCleanup [[-PolicyId] <String>] [[-KeepCount] <Int32>] [[-KeepDays] <Int32>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Cleans up old snapshots keeping only the specified number of recent ones
or those within a time window.

## EXAMPLES

### EXAMPLE 1
```
Invoke-PolicySnapshotCleanup -PolicyId "abc123" -KeepCount 5
```

### EXAMPLE 2
```
Invoke-PolicySnapshotCleanup -KeepDays 7
```

## PARAMETERS

### -PolicyId
The ID of the policy to clean up snapshots for.
If not specified, cleans all.

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

### -KeepCount
Number of most recent snapshots to keep.
Default is 10.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeepDays
Keep all snapshots from the last N days.
Default is 30.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would be deleted without actually deleting.

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

### [PSCustomObject] Cleanup result with Success, Data (removed count), and Error.
## NOTES

## RELATED LINKS
