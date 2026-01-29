---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Initialize-ADStructure

## SYNOPSIS
Creates the AppLocker OU and security groups in Active Directory.

## SYNTAX

```
Initialize-ADStructure [[-OUName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Creates:
- OU=AppLocker at domain root
- Security groups inside the AppLocker OU:
  - AppLocker-Admins
  - AppLocker-Exempt
  - AppLocker-Audit
  - AppLocker-Users
  - AppLocker-Installers
  - AppLocker-Developers

## EXAMPLES

### EXAMPLE 1
```
Initialize-ADStructure
```

Creates the AppLocker OU and all security groups.

## PARAMETERS

### -OUName
Name of the OU to create.
Default is 'AppLocker'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: AppLocker
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, Data, and Error properties.
## NOTES

## RELATED LINKS
