---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-AppLockerRuleSids

## SYNOPSIS
Validates all Security Identifiers (SIDs) in AppLocker rules.

## SYNTAX

```
Test-AppLockerRuleSids [-XmlPath] <String> [-ResolveNames] [<CommonParameters>]
```

## DESCRIPTION
Ensures UserOrGroupSid values are:
- Present on every rule
- Valid SID format (S-1-...)
- Optionally resolvable to a security principal

## EXAMPLES

### EXAMPLE 1
```
Test-AppLockerRuleSids -XmlPath "C:\Policies\baseline.xml"
```

### EXAMPLE 2
```
Test-AppLockerRuleSids -XmlPath "C:\Policies\baseline.xml" -ResolveNames
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

### -ResolveNames
If specified, attempts to resolve SIDs to account names.

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

### [PSCustomObject] with Success, Errors, UnresolvedSids, SidMappings properties
## NOTES

## RELATED LINKS
