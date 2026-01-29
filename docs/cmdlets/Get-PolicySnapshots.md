---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-PolicySnapshots

## SYNOPSIS
Retrieves all snapshots for a policy.

## SYNTAX

```
Get-PolicySnapshots [-PolicyId] <String> [[-Limit] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Lists all available snapshots for the specified policy, sorted by creation date.

## EXAMPLES

### EXAMPLE 1
```
Get-PolicySnapshots -PolicyId "abc123"
```

### EXAMPLE 2
```
Get-PolicySnapshots -PolicyId "abc123" -Limit 10
```

## PARAMETERS

### -PolicyId
The ID of the policy to get snapshots for.

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

### -Limit
Maximum number of snapshots to return.
Default is 50.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 50
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] List of snapshots with Success, Data, and Error.
## NOTES

## RELATED LINKS
