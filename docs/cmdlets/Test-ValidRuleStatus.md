---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-ValidRuleStatus

## SYNOPSIS
Validates a rule status.

## SYNTAX

```
Test-ValidRuleStatus [-Status] <String> [<CommonParameters>]
```

## DESCRIPTION
Validates a rule status.
Returns $true if the input matches the expected format, $false otherwise.

## EXAMPLES

### EXAMPLE 1
```
Test-ValidRuleStatus -Status 'Approved'
```

## PARAMETERS

### -Status
The status to validate.

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

### [bool] True if valid status
## NOTES

## RELATED LINKS
