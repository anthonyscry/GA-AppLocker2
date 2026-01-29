---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-Rule

## SYNOPSIS
Retrieves rules from storage.

## SYNTAX

### All (Default)
```
Get-Rule [<CommonParameters>]
```

### ById
```
Get-Rule [-Id <String>] [<CommonParameters>]
```

### Filter
```
Get-Rule [-Name <String>] [-RuleType <String>] [-CollectionType <String>] [-Status <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets one or more AppLocker rules from local storage.
Can filter by ID, name, type, collection, or status.

## EXAMPLES

### EXAMPLE 1
```
Get-Rule -Id '12345678-...'
```

### EXAMPLE 2
```
Get-Rule -RuleType Publisher -Status Approved
```

### EXAMPLE 3
```
Get-Rule -Name '*Microsoft*'
```

## PARAMETERS

### -Id
Specific rule GUID to retrieve.

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

### -Name
Filter by rule name (supports wildcards).

```yaml
Type: String
Parameter Sets: Filter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RuleType
Filter by rule type: Publisher, Hash, Path.

```yaml
Type: String
Parameter Sets: Filter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CollectionType
Filter by collection: Exe, Dll, Msi, Script, Appx.

```yaml
Type: String
Parameter Sets: Filter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Filter by status: Pending, Approved, Rejected, Review.

```yaml
Type: String
Parameter Sets: Filter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success and Data (rule or array of rules).
## NOTES

## RELATED LINKS
