---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-ValidHash

## SYNOPSIS
Validates a SHA256 hash string.

## SYNTAX

```
Test-ValidHash [-Hash] <String> [<CommonParameters>]
```

## DESCRIPTION
Validates a SHA256 hash string.
Returns $true if the input matches the expected format, $false otherwise.

## EXAMPLES

### EXAMPLE 1
```
Test-ValidHash -Hash 'A1B2C3D4E5F6...'
```

## PARAMETERS

### -Hash
The hash string to validate.

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

### [bool] True if valid SHA256 hash format
## NOTES

## RELATED LINKS
