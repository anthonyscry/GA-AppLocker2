---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Assert-InRange

## SYNOPSIS
Asserts that a numeric value is within a range.

## SYNTAX

```
Assert-InRange [-Value] <Object> [[-Minimum] <Object>] [[-Maximum] <Object>] [-ParameterName] <String>
 [<CommonParameters>]
```

## DESCRIPTION
Asserts that a numeric value is within a range.
Throws \[System.ArgumentException\] if the assertion fails.
Use for parameter validation.

## EXAMPLES

### EXAMPLE 1
```
Assert-InRange -Value $port -Minimum 1 -Maximum 65535 -ParameterName 'Port'
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

### -Minimum
Minimum allowed value (inclusive).

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Maximum
Maximum allowed value (inclusive).

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
