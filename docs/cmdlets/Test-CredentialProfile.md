---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-CredentialProfile

## SYNOPSIS
Tests a credential profile against a target machine.

## SYNTAX

```
Test-CredentialProfile [-Name] <String> [-ComputerName] <String> [<CommonParameters>]
```

## DESCRIPTION
Validates that a credential profile can successfully authenticate
to a target machine via WinRM.

## EXAMPLES

### EXAMPLE 1
```
Test-CredentialProfile -Name 'DomainAdmin' -ComputerName 'DC01'
```

## PARAMETERS

### -Name
Name of the credential profile to test.

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

### -ComputerName
Target machine to test against.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, Data (test details), and Error.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
