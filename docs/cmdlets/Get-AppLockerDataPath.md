---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-AppLockerDataPath

## SYNOPSIS
Returns the application data directory path for GA-AppLocker.

## SYNTAX

```
Get-AppLockerDataPath [<CommonParameters>]
```

## DESCRIPTION
Returns the standardized path where GA-AppLocker stores all data
including scans, credentials, policies, rules, settings, and logs.
Creates the directory if it doesn't exist.

## EXAMPLES

### EXAMPLE 1
```
$path = Get-AppLockerDataPath
```

Returns: C:\Users\{user}\AppData\Local\GA-AppLocker

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [string] The full path to the GA-AppLocker data directory.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
