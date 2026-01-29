---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-CredentialForTier

## SYNOPSIS
Gets the appropriate credential for a machine tier.

## SYNTAX

```
Get-CredentialForTier [-Tier] <Int32> [[-ProfileName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns a PSCredential object for the specified tier.
Uses the default credential for that tier, or the first available.

## EXAMPLES

### EXAMPLE 1
```
$cred = Get-CredentialForTier -Tier 1
```

Invoke-Command -ComputerName 'Server01' -Credential $cred.Data -ScriptBlock { ...
}

## PARAMETERS

### -Tier
Machine tier: 0 (DC), 1 (Server), 2 (Workstation).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileName
Specific profile name to use instead of default.

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

### [PSCustomObject] Result with Success, Data (PSCredential), and Error.
## NOTES
Returns decrypted PSCredential object for use in remoting.

## RELATED LINKS
