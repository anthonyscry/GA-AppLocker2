---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Get-RemoteArtifacts

## SYNOPSIS
Collects AppLocker-relevant artifacts from remote machines via WinRM.

## SYNTAX

```
Get-RemoteArtifacts [-ComputerName] <String[]> [[-Credential] <PSCredential>] [[-Paths] <String[]>]
 [[-Extensions] <String[]>] [-Recurse] [-SkipDllScanning] [[-ThrottleLimit] <Int32>] [[-BatchSize] <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Uses PowerShell remoting to scan remote machines for executable files
and collect metadata including hash, publisher, and signature info.

## EXAMPLES

### EXAMPLE 1
```
Get-RemoteArtifacts -ComputerName 'Server01', 'Server02'
```

### EXAMPLE 2
```
$cred = Get-Credential
```

Get-RemoteArtifacts -ComputerName 'Workstation01' -Credential $cred -Recurse

## PARAMETERS

### -ComputerName
Name(s) of remote computer(s) to scan.

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

### -Credential
PSCredential for authentication.
If not provided, uses default for machine tier.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Paths
Array of paths to scan on remote machines.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (Get-DefaultScanPaths)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Extensions
File extensions to collect.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: @('.exe', '.dll', '.msi', '.ps1')
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

### -ThrottleLimit
Maximum concurrent remote sessions.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -BatchSize
{{ Fill BatchSize Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 50
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
