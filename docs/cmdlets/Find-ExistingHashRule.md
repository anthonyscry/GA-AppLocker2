---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Find-ExistingHashRule

## SYNOPSIS
Checks if a hash rule already exists.

## SYNTAX

```
Find-ExistingHashRule [-Hash] <String> [[-CollectionType] <String>] [<CommonParameters>]
```

## DESCRIPTION
Efficiently checks if a rule with the same hash already exists.
Uses the Storage layer's indexed lookup for O(1) performance.
Falls back to JSON file scan if Storage layer unavailable.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Hash
The SHA256 hash to check for.

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

### -CollectionType
The collection type (Exe, Dll, Msi, Script, Appx).

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

### [PSCustomObject] Existing rule if found, $null otherwise.
## NOTES

## RELATED LINKS
