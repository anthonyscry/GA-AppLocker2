---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-PolicySnapshot

## SYNOPSIS
Functions for creating and managing policy snapshots (versioned backups).

## SYNTAX

```
New-PolicySnapshot [-PolicyId] <String> [[-Description] <String>] [[-CreatedBy] <String>] [<CommonParameters>]
```

## DESCRIPTION
Provides snapshot functionality for AppLocker policies allowing:
- Point-in-time backups before changes
- Version history with metadata
- Easy rollback to previous states
- Audit trail of policy changes

## EXAMPLES

### EXAMPLE 1
```
New-PolicySnapshot
```

# New PolicySnapshot

## PARAMETERS

### -PolicyId
{{ Fill PolicyId Description }}

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

### -Description
{{ Fill Description Description }}

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

### -CreatedBy
{{ Fill CreatedBy Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
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
