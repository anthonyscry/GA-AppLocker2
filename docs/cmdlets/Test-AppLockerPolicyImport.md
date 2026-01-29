---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-AppLockerPolicyImport

## SYNOPSIS
Tests if a policy can be imported by AppLocker without errors.

## SYNTAX

```
Test-AppLockerPolicyImport [-XmlPath] <String> [<CommonParameters>]
```

## DESCRIPTION
This is the DEFINITIVE test - it attempts to parse the policy
using the same API that Set-AppLockerPolicy uses.
If this passes,
the policy WILL be accepted by AppLocker.

Falls back to structural XML validation when the AppLocker cmdlets
are not available (e.g., non-domain machines, missing RSAT).

## EXAMPLES

### EXAMPLE 1
```
Test-AppLockerPolicyImport -XmlPath "C:\Policies\baseline.xml"
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] with Success, Error, ParsedPolicy, CanImport properties
## NOTES
This is the most critical validation - it uses Microsoft's own parser.

## RELATED LINKS
