---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-DeploymentJob

## SYNOPSIS
Retrieves a deployment job by ID.

## SYNTAX

```
Get-DeploymentJob [-JobId] <String> [<CommonParameters>]
```

## DESCRIPTION
Retrieves a deployment job by ID.
Returns the requested data wrapped in a standard result object with Success, Data, and Error properties.

## EXAMPLES

### EXAMPLE 1
```
Get-DeploymentJob -JobId "abc123"
```

## PARAMETERS

### -JobId
The unique identifier of the deployment job.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
