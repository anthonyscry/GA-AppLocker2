---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Assert-NotNullOrEmpty

## SYNOPSIS
Asserts that a value is not null or empty.

## SYNTAX

```
Assert-NotNullOrEmpty [-Value] <Object> [-ParameterName] <String> [[-Message] <String>] [<CommonParameters>]
```

## DESCRIPTION
Asserts that a value is not null or empty.
Throws \[System.ArgumentException\] if the assertion fails.
Use for parameter validation.

## EXAMPLES

### EXAMPLE 1
```
Assert-NotNullOrEmpty -Value $hash -ParameterName 'Hash'
```

## PARAMETERS

### -Value
The value to check.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
Position: 2
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
Position: 3
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
