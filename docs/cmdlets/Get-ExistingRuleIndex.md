---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-ExistingRuleIndex

## SYNOPSIS
Returns HashSets for O(1) rule existence checks.

## SYNTAX

```
Get-ExistingRuleIndex [<CommonParameters>]
```

## DESCRIPTION
Used by batch generation to quickly check if rules already exist.
Returns Hashes and Publishers as HashSets for Contains() checks.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSCustomObject with Hashes (HashSet) and Publishers (HashSet) properties.
## NOTES

## RELATED LINKS
