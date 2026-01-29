---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-Policy

## SYNOPSIS
Retrieves a policy by ID or name.

## SYNTAX

```
Get-Policy [[-PolicyId] <String>] [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a policy by ID or name.
Returns the requested data wrapped in a standard result object with Success, Data, and Error properties.

## EXAMPLES

### EXAMPLE 1
```
Get-Policy -PolicyId "abc123"
```

Get-Policy -Name "Baseline Policy"

## PARAMETERS

### -PolicyId
The unique identifier of the policy.

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

### -Name
The name of the policy to find.

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
