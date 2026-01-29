---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Assert-MatchesPattern

## SYNOPSIS
Asserts that a value matches a pattern.

## SYNTAX

```
Assert-MatchesPattern [-Value] <String> [-Pattern] <String> [-ParameterName] <String> [[-Message] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Asserts that a value matches a pattern.
Throws \[System.ArgumentException\] if the assertion fails.
Use for parameter validation.

## EXAMPLES

### EXAMPLE 1
```
Assert-MatchesPattern -Value $hash -Pattern '^[A-Fa-f0-9]{64}$' -ParameterName 'Hash' -Message 'Invalid SHA256 hash format'
```

## PARAMETERS

### -Value
The value to check.

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

### -Pattern
Regex pattern to match.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParameterName
Name of the parameter for error message.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Message
Custom error message.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Throws if validation fails, otherwise returns nothing
## NOTES

## RELATED LINKS
