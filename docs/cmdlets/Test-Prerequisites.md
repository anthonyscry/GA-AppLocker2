---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-Prerequisites

## SYNOPSIS
Validates that all prerequisites for GA-AppLocker are met.

## SYNTAX

```
Test-Prerequisites [<CommonParameters>]
```

## DESCRIPTION
Checks for required PowerShell modules (RSAT), .NET Framework version,
domain membership, and administrator privileges.
Returns a detailed
result object with pass/fail status for each check.

## EXAMPLES

### EXAMPLE 1
```
$prereqs = Test-Prerequisites
```

if (-not $prereqs.AllPassed) {
    $prereqs.Checks | Where-Object { -not $_.Passed }
}

Checks prerequisites and displays any failures.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Object with AllPassed boolean and Checks array.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
