---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-OUTree

## SYNOPSIS
Retrieves the Active Directory OU tree structure.

## SYNTAX

```
Get-OUTree [[-SearchBase] <String>] [[-IncludeComputerCount] <Boolean>] [-UseLdap] [[-Server] <String>]
 [[-Port] <Int32>] [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Builds a hierarchical tree of Organizational Units.
Falls back to LDAP when ActiveDirectory module is not available.

## EXAMPLES

### EXAMPLE 1
```
$tree = Get-OUTree
```

$tree.Data | Format-Table Name, Path, ComputerCount

## PARAMETERS

### -SearchBase
The distinguished name of the OU to start from.

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

### -IncludeComputerCount
Include the count of computers in each OU.
Default: $true

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

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
{{ Fill Server Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
{{ Fill Port Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result object with Success, Data (array of OUs), and Error.
## NOTES

## RELATED LINKS
