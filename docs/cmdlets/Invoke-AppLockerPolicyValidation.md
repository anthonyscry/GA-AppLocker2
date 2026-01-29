---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Invoke-AppLockerPolicyValidation

## SYNOPSIS
Runs complete validation pipeline on an AppLocker policy.

## SYNTAX

```
Invoke-AppLockerPolicyValidation [-XmlPath] <String> [-StopOnFirstError] [[-OutputReport] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Executes all validation checks in sequence:
1.
XML Schema validation
2.
GUID validation (format, uppercase, uniqueness)
3.
SID validation (format, well-known resolution)
4.
Rule condition validation (publisher, hash, path)
5.
Live import test (Microsoft parser)

## EXAMPLES

### EXAMPLE 1
```
Invoke-AppLockerPolicyValidation -XmlPath "C:\Policies\new-policy.xml"
```

### EXAMPLE 2
```
Invoke-AppLockerPolicyValidation -XmlPath "C:\Policies\new-policy.xml" -OutputReport "C:\Reports\validation.json"
```

## PARAMETERS

### -XmlPath
Path to the AppLocker policy XML file.

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

### -StopOnFirstError
If specified, stops validation on first error found.

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

### -OutputReport
Path to save detailed validation report as JSON.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] with complete validation results including
### OverallSuccess, CanBeImported, TotalErrors, TotalWarnings,
### and individual stage results.
## NOTES

## RELATED LINKS
