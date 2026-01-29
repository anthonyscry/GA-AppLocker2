---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-GPOExists

## SYNOPSIS
Tests if a GPO exists.

## SYNTAX

```
Test-GPOExists [-GPOName] <String> [<CommonParameters>]
```

## DESCRIPTION
Tests if a GPO exists.
Returns a result object indicating success or failure.
Check the Success property of the returned hashtable.

## EXAMPLES

### EXAMPLE 1
```
Test-GPOExists -GPOName "AppLocker-Workstations"
```

## PARAMETERS

### -GPOName
The name of the GPO to check.

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
