---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# ConvertTo-SafeXmlString

## SYNOPSIS
Sanitizes a string for safe use in XML content.

## SYNTAX

```
ConvertTo-SafeXmlString [-Value] <String> [<CommonParameters>]
```

## DESCRIPTION
Sanitizes a string for safe use in XML content.
Transforms input to a safe format.

## EXAMPLES

### EXAMPLE 1
```
& more'
```

# Returns: 'Test &lt;value&gt; &amp; more'

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [string] XML-escaped string
## NOTES

## RELATED LINKS
