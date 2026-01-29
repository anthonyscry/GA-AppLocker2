---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-AllPolicies

## SYNOPSIS
Retrieves all policies.

## SYNTAX

```
Get-AllPolicies [[-Status] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves all policies.

## EXAMPLES

### EXAMPLE 1
```
Get-AllPolicies
```

Get-AllPolicies -Status "Active"

## PARAMETERS

### -Status
Optional filter by status (Draft, Active, Deployed, Archived).

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
