---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Backup-AppLockerData

## SYNOPSIS
Creates a full backup of GA-AppLocker data.

## SYNTAX

```
Backup-AppLockerData [-OutputPath] <String> [-IncludeCredentials] [-IncludeAuditLog] [[-Description] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a full backup of GA-AppLocker data.
Creates a backup copy for disaster recovery.

## EXAMPLES

### EXAMPLE 1
```
Backup-AppLockerData -OutputPath 'C:\Backups\applocker-backup.zip'
```

### EXAMPLE 2
```
Backup-AppLockerData -OutputPath 'C:\Backups\backup.zip' -Description 'Pre-upgrade backup'
```

## PARAMETERS

### -OutputPath
Path for the backup file (.zip).

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

### -IncludeCredentials
Include encrypted credential files (default: $true).

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
Include audit log history (default: $true).

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

### -Description
Optional description for the backup.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
