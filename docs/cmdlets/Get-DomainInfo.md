---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-DomainInfo

## SYNOPSIS
Retrieves Active Directory domain information.

## SYNTAX

```
Get-DomainInfo [-UseLdap] [[-Server] <String>] [[-Port] <Int32>] [[-Credential] <PSCredential>]
 [<CommonParameters>]
```

## DESCRIPTION
Auto-detects the current domain and returns domain details.
Falls back to LDAP when ActiveDirectory module is not available.

## EXAMPLES

### EXAMPLE 1
```
$domain = Get-DomainInfo
```

Write-Host "Connected to: $($domain.Data.DnsRoot)"

## PARAMETERS

### -UseLdap
Force using LDAP instead of AD module.

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

### -Server
LDAP server to connect to (for LDAP fallback).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
LDAP port (default: 389).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 389
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
{{ Fill Credential Description }}

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result object with Success, Data, and Error properties.
## NOTES

## RELATED LINKS
