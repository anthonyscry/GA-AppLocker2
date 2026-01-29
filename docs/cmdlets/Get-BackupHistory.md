---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-BackupHistory

## SYNOPSIS
Lists available backups in a directory.

## SYNTAX

```
Get-BackupHistory [-BackupDirectory] <String> [[-Last] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Lists available backups in a directory.
Returns the requested data in a standard result object.

## EXAMPLES

### EXAMPLE 1
```
Get-BackupHistory -BackupDirectory 'C:\Backups'
```

### EXAMPLE 2
```
Get-BackupHistory -BackupDirectory 'C:\Backups' -Last 5
```

## PARAMETERS

### -BackupDirectory
Directory containing backup files.

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

### -Last
Return only the last N backups.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
