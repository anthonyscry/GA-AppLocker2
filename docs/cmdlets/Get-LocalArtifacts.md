---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-LocalArtifacts

## SYNOPSIS
Collects AppLocker-relevant artifacts from the local machine.

## SYNTAX

```
Get-LocalArtifacts [[-Paths] <String[]>] [[-Extensions] <String[]>] [-Recurse] [[-MaxDepth] <Int32>]
 [-SkipDllScanning] [[-SyncHash] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Scans specified paths on the local machine for executable files
and collects metadata including hash, publisher, and signature info.

## EXAMPLES

### EXAMPLE 1
```
Get-LocalArtifacts
```

### EXAMPLE 2
```
Get-LocalArtifacts -Paths 'C:\CustomApps' -Recurse
```

## PARAMETERS

### -Paths
Array of paths to scan.
Defaults to Program Files and System32.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-DefaultScanPaths)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Extensions
File extensions to collect.
Defaults to exe, dll, msi, ps1, etc.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $script:ArtifactExtensions
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recurse
Scan subdirectories recursively.

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

### -MaxDepth
Maximum recursion depth (default: unlimited).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipDllScanning
{{ Fill SkipDllScanning Description }}

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
Position: 4
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
