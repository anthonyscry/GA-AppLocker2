---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Restore-PolicySnapshot

## SYNOPSIS
Restores a policy to a previous snapshot state.

## SYNTAX

```
Restore-PolicySnapshot [-SnapshotId] <String> [[-CreateBackup] <Boolean>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Reverts a policy and its rules to the state captured in a snapshot.
Automatically creates a new snapshot before restoring for safety.

## EXAMPLES

### EXAMPLE 1
```
Restore-PolicySnapshot -SnapshotId "abc123_20260122_143000"
```

### EXAMPLE 2
```
Restore-PolicySnapshot -SnapshotId "abc123_20260122_143000" -CreateBackup:$false -Force
```

## PARAMETERS

### -SnapshotId
The ID of the snapshot to restore.

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

### -CreateBackup
If true (default), creates a backup snapshot before restoring.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
If specified, skips confirmation for destructive operation.

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
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

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

### [PSCustomObject] Restore result with Success, Data, and Error.
## NOTES

## RELATED LINKS
