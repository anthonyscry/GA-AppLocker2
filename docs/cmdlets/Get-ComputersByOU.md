---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-ComputersByOU

## SYNOPSIS
Retrieves computers from specified Organizational Units.

## SYNTAX

```
Get-ComputersByOU [-OUDistinguishedNames] <String[]> [[-IncludeNestedOUs] <Boolean>] [-UseLdap]
 [[-Server] <String>] [[-Port] <Int32>] [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Gets all computer objects from one or more OUs.
Falls back to LDAP when ActiveDirectory module is not available.

## EXAMPLES

### EXAMPLE 1
```
$computers = Get-ComputersByOU -OUDistinguishedNames @('OU=Workstations,DC=corp,DC=local')
```

$computers.Data | Format-Table Hostname, OperatingSystem, MachineType

## PARAMETERS

### -OUDistinguishedNames
Array of OU distinguished names to search.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeNestedOUs
Search nested OUs recursively.
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

### [PSCustomObject] Result object with Success, Data (array of computers), and Error.
## NOTES

## RELATED LINKS
