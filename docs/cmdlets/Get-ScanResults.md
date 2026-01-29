---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-ScanResults

## SYNOPSIS
Retrieves saved scan results.

## SYNTAX

### List (Default)
```
Get-ScanResults [<CommonParameters>]
```

### ById
```
Get-ScanResults [-ScanId <String>] [<CommonParameters>]
```

### Latest
```
Get-ScanResults [-Latest] [<CommonParameters>]
```

## DESCRIPTION
Loads previously saved scan results from storage.

## EXAMPLES

### EXAMPLE 1
```
Get-ScanResults -Latest
```

## PARAMETERS

### -ScanId
GUID of a specific scan to retrieve.

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

### -Latest
Get the most recent scan.

```yaml
Type: SwitchParameter
Parameter Sets: Latest
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

### [PSCustomObject] Scan data.
## NOTES

## RELATED LINKS
