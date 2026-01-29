---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Start-ArtifactScan

## SYNOPSIS
Orchestrates artifact scanning across multiple machines.

## SYNTAX

```
Start-ArtifactScan [[-Machines] <Array>] [-ScanLocal] [-IncludeEventLogs] [[-Paths] <String[]>] [-SaveResults]
 [[-ScanName] <String>] [[-ThrottleLimit] <Int32>] [[-BatchSize] <Int32>] [-SkipDllScanning] [-IncludeAppx]
 [[-SyncHash] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Main entry point for artifact scanning.
Manages credential selection,
parallel execution, and result aggregation for multi-machine scans.

## EXAMPLES

### EXAMPLE 1
```
$machines = (Get-ComputersByOU -OUDistinguishedNames 'OU=Servers,DC=domain,DC=com').Data
```

Start-ArtifactScan -Machines $machines -IncludeEventLogs

### EXAMPLE 2
```
Start-ArtifactScan -ScanLocal -SaveResults -ScanName 'LocalBaseline'
```

### EXAMPLE 3
```
Start-ArtifactScan -Machines $machines -ThrottleLimit 10 -BatchSize 25
```

## PARAMETERS

### -Machines
Array of machine objects from Get-ComputersByOU or similar.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScanLocal
Include the local machine in the scan.

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

### -IncludeEventLogs
Also collect AppLocker event logs.

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

### -Paths
Custom paths to scan (defaults to Program Files).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SaveResults
Save results to scan storage folder.

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

### -ScanName
Name for this scan (used for saved results).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: "Scan_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThrottleLimit
Maximum concurrent remote sessions (default: 5).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -BatchSize
Number of machines to process per batch (default: 50).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 50
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

### -IncludeAppx
{{ Fill IncludeAppx Description }}

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
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success, Data (all artifacts), and Summary.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
