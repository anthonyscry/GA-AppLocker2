---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-AppLockerXmlSchema

## SYNOPSIS
Validates AppLocker policy XML against Microsoft schema requirements.

## SYNTAX

### Path
```
Test-AppLockerXmlSchema -XmlPath <String> [<CommonParameters>]
```

### Content
```
Test-AppLockerXmlSchema -XmlContent <String> [<CommonParameters>]
```

## DESCRIPTION
Performs structural validation of AppLocker XML including:
- Root element validation
- Required Version attribute
- RuleCollection Type (case-sensitive: Appx, Dll, Exe, Msi, Script)
- EnforcementMode (case-sensitive: NotConfigured, AuditOnly, Enabled)
- Rule counting per collection

## EXAMPLES

### EXAMPLE 1
```
Test-AppLockerXmlSchema -XmlPath "C:\Policies\baseline.xml"
```

### EXAMPLE 2
```
Test-AppLockerXmlSchema -XmlContent $xmlString
```

## PARAMETERS

### -XmlPath
Path to the AppLocker policy XML file.

```yaml
Type: String
Parameter Sets: Path
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -XmlContent
XML content as string (alternative to XmlPath).

```yaml
Type: String
Parameter Sets: Content
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] with Success, Errors, Warnings, Details properties
## NOTES

## RELATED LINKS
