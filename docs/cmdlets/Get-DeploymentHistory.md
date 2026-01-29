---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-DeploymentHistory

## SYNOPSIS
Gets deployment history entries.

## SYNTAX

```
Get-DeploymentHistory [[-JobId] <String>] [[-Limit] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Gets deployment history entries.

## EXAMPLES

### EXAMPLE 1
```
Get-DeploymentHistory
```

Get-DeploymentHistory -JobId "abc123"

## PARAMETERS

### -JobId
Optional filter by job ID.

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

### -Limit
Maximum number of entries to return.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
