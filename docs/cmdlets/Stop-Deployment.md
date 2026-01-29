---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Stop-Deployment

## SYNOPSIS
Cancels a pending or running deployment.

## SYNTAX

```
Stop-Deployment [-JobId] <String> [<CommonParameters>]
```

## DESCRIPTION
Cancels a pending or running deployment.
Gracefully stops the running operation.

## EXAMPLES

### EXAMPLE 1
```
Stop-Deployment -JobId "abc123"
```

## PARAMETERS

### -JobId
The ID of the deployment job to cancel.

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
