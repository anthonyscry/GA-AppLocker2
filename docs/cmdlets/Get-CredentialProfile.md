---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-CredentialProfile

## SYNOPSIS
Retrieves credential profiles from storage.

## SYNTAX

### ByName (Default)
```
Get-CredentialProfile [-Name <String>] [<CommonParameters>]
```

### ById
```
Get-CredentialProfile [-Id <String>] [<CommonParameters>]
```

### ByTier
```
Get-CredentialProfile [-Tier <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Gets one or more credential profiles by name, ID, or tier.
Returns profile metadata (password remains encrypted).

## EXAMPLES

### EXAMPLE 1
```
Get-CredentialProfile -Name 'DomainAdmin'
```

### EXAMPLE 2
```
Get-CredentialProfile -Tier 0
```

## PARAMETERS

### -Name
Name of the credential profile to retrieve.

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
GUID of the credential profile to retrieve.

```yaml
Type: String
Parameter Sets: ById
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tier
Get all profiles for a specific tier.

```yaml
Type: Int32
Parameter Sets: ByTier
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, Data (profile(s)), and Error.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
