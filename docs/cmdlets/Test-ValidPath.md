---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-ValidPath

## SYNOPSIS
Validates a file path string.

## SYNTAX

```
Test-ValidPath [-Path] <String> [-MustExist] [<CommonParameters>]
```

## DESCRIPTION
Validates a file path string.
Returns $true if the input matches the expected format, $false otherwise.

## EXAMPLES

### EXAMPLE 1
```
Test-ValidPath -Path 'C:\Program Files\App\app.exe'
```

### EXAMPLE 2
```
Test-ValidPath -Path 'C:\Config\settings.json' -MustExist
```

## PARAMETERS

### -Path
The path string to validate.

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

### -MustExist
If specified, also checks if the path exists.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [bool] True if valid path format (and exists if MustExist specified)
## NOTES

## RELATED LINKS
