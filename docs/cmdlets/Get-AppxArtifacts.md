---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-AppxArtifacts

## SYNOPSIS
Collects installed Appx/MSIX packages for AppLocker rule generation.

## SYNTAX

```
Get-AppxArtifacts [-AllUsers] [-IncludeFrameworks] [-IncludeSystemApps] [[-SyncHash] <Hashtable>]
 [<CommonParameters>]
```

## DESCRIPTION
Enumerates installed Windows App packages (UWP/MSIX) using Get-AppxPackage.
These packaged apps require special handling in AppLocker as they use
Publisher rules based on package publisher certificates.

## EXAMPLES

### EXAMPLE 1
```
Get-AppxArtifacts
```

Returns user-installed Appx packages.

### EXAMPLE 2
```
Get-AppxArtifacts -AllUsers -IncludeSystemApps
```

Returns all Appx packages including system apps.

## PARAMETERS

### -AllUsers
Include packages installed for all users (requires admin).

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

### -IncludeFrameworks
Include framework packages (Microsoft.NET, VCLibs, etc.).

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

### -IncludeSystemApps
Include Windows system apps (Calculator, Photos, etc.).

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

### -SyncHash
{{ Fill SyncHash Description }}

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, Data (artifacts array), and Summary.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
