---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Remove-CredentialProfile

## SYNOPSIS
Removes a credential profile from storage.

## SYNTAX

### ByName (Default)
```
Remove-CredentialProfile -Name <String> [-Force] [<CommonParameters>]
```

### ById
```
Remove-CredentialProfile -Id <String> [-Force] [<CommonParameters>]
```

## DESCRIPTION
Deletes a saved credential profile by name or ID.

## EXAMPLES

### EXAMPLE 1
```
Remove-CredentialProfile -Name 'OldAdmin'
```

### EXAMPLE 2
```
Remove-CredentialProfile -Id '12345678-1234-1234-1234-123456789012' -Force
```

## PARAMETERS

### -Name
Name of the credential profile to remove.

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
GUID of the credential profile to remove.

```yaml
Type: String
Parameter Sets: ById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Skip confirmation prompt.

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

### [PSCustomObject] Result with Success and Error.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
