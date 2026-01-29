---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-CredentialProfile

## SYNOPSIS
Creates a new credential profile for GA-AppLocker scanning.

## SYNTAX

```
New-CredentialProfile [-Name] <String> [-Credential] <PSCredential> [-Tier] <Int32> [[-Description] <String>]
 [-SetAsDefault] [<CommonParameters>]
```

## DESCRIPTION
Saves a credential profile with tier assignment for use during
machine scanning.
Credentials are encrypted using Windows DPAPI.

## EXAMPLES

### EXAMPLE 1
```
$cred = Get-Credential
```

New-CredentialProfile -Name 'DomainAdmin' -Credential $cred -Tier 0

### EXAMPLE 2
```
New-CredentialProfile -Name 'ServerAdmin' -Credential $cred -Tier 1 -SetAsDefault
```

## PARAMETERS

### -Name
Unique name for the credential profile.

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

### -Credential
PSCredential object containing username and password.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tier
Machine tier this credential is for: 0 (DC), 1 (Server), 2 (Workstation).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Optional description for the credential profile.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SetAsDefault
Set this credential as the default for its tier.

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

### [PSCustomObject] Result with Success, Data (profile), and Error.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
