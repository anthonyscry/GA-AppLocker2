---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-SetupStatus

## SYNOPSIS
Gets the current status of AppLocker environment setup.

## SYNTAX

```
Get-SetupStatus [<CommonParameters>]
```

## DESCRIPTION
Checks the status of:
- WinRM GPO (exists, linked, enabled)
- AppLocker GPOs (DC, Servers, Workstations)
- AppLocker OU and security groups

## EXAMPLES

### EXAMPLE 1
```
Get-SetupStatus
```

Returns the current setup status.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Status information for all setup components.
## NOTES

## RELATED LINKS
