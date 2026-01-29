---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-ValidDistinguishedName

## SYNOPSIS
Validates a Distinguished Name (DN) string.

## SYNTAX

```
Test-ValidDistinguishedName [-DistinguishedName] <String> [<CommonParameters>]
```

## DESCRIPTION
Validates a Distinguished Name (DN) string.
Returns $true if the input matches the expected format, $false otherwise.

## EXAMPLES

### EXAMPLE 1
```
Test-ValidDistinguishedName -DistinguishedName 'OU=Computers,DC=corp,DC=local'
```

## PARAMETERS

### -DistinguishedName
The DN string to validate.

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

### [bool] True if valid DN format
## NOTES

## RELATED LINKS
