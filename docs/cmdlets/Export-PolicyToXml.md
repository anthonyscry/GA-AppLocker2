---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Export-PolicyToXml

## SYNOPSIS
Exports a policy to AppLocker-compatible XML format.

## SYNTAX

```
Export-PolicyToXml [-PolicyId] <String> [-OutputPath] <String> [-IncludeRejected] [[-PhaseOverride] <Int32>]
 [-SkipValidation] [<CommonParameters>]
```

## DESCRIPTION
Generates a complete AppLocker policy XML that can be
imported into Group Policy.
Uses the canonical rule schema
from GA-AppLocker.Rules module.

Supports phase-based filtering:
- Phase 1: EXE rules only (AuditOnly)
- Phase 2: EXE + Script rules (AuditOnly)
- Phase 3: EXE + Script + MSI rules (AuditOnly)
- Phase 4: All rules including DLL/Appx (Enabled)

## EXAMPLES

### EXAMPLE 1
```
Export-PolicyToXml -PolicyId "abc123" -OutputPath "C:\Policies\baseline.xml"
```

### EXAMPLE 2
```
Export-PolicyToXml -PolicyId "abc123" -OutputPath "C:\Policies\phase2.xml" -PhaseOverride 2
```

### EXAMPLE 3
```
Export-PolicyToXml -PolicyId "abc123" -OutputPath "C:\Policies\quick.xml" -SkipValidation
```

## PARAMETERS

### -PolicyId
The unique identifier of the policy.

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

### -OutputPath
The path to save the XML file.

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

### -IncludeRejected
Include rejected rules in export (default: false).

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

### -PhaseOverride
Override the policy's Phase setting for this export.
Useful for testing different phases without modifying the policy.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipValidation
If specified, skips the 5-stage validation pipeline after export.
By default, exported XML is validated automatically.

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

## NOTES

## RELATED LINKS
