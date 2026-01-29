---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Restore-AppLockerData

## SYNOPSIS
Restores GA-AppLocker data from a backup.

## SYNTAX

```
Restore-AppLockerData [-BackupPath] <String> [-RestoreCredentials] [-RestoreAuditLog] [-Force]
 [<CommonParameters>]
```

## DESCRIPTION
Restores GA-AppLocker data from a backup.
Restores from a previously saved version.

## EXAMPLES

### EXAMPLE 1
```
Restore-AppLockerData -BackupPath 'C:\Backups\applocker-backup.zip'
```

### EXAMPLE 2
```
Restore-AppLockerData -BackupPath 'C:\Backups\backup.zip' -Force
```

## PARAMETERS

### -BackupPath
Path to the backup .zip file.

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

### -RestoreCredentials
Restore credential files (default: $true).
Note: DPAPI-encrypted credentials
may only work on the original machine/user.

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

### -RestoreAuditLog
Restore audit log history (default: $true).

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

### -Force
Overwrite existing data without prompting.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
