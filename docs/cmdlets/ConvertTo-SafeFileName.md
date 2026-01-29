---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# ConvertTo-SafeFileName

## SYNOPSIS
Sanitizes a string for safe use in file names.

## SYNTAX

```
ConvertTo-SafeFileName [-Value] <String> [[-Replacement] <Char>] [<CommonParameters>]
```

## DESCRIPTION
Sanitizes a string for safe use in file names.
Transforms input to a safe format.

## EXAMPLES

### EXAMPLE 1
```
'
```

# Returns: 'My Rule_ Test _1_'

## PARAMETERS

### -Value
The string to sanitize.

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

### -Replacement
Character to replace invalid chars with.
Default is underscore.

```yaml
Type: Char
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: _
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [string] Sanitized string safe for file names
## NOTES

## RELATED LINKS
