---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-MachineConnectivity

## SYNOPSIS
Tests network connectivity and WinRM availability for machines.

## SYNTAX

```
Test-MachineConnectivity [-Machines] <Array> [[-TestWinRM] <Boolean>] [[-TimeoutSeconds] <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Performs ping and WinRM connectivity tests on a list of machines.
Updates IsOnline and WinRMStatus properties on each machine object.

## EXAMPLES

### EXAMPLE 1
```
$machines = (Get-ComputersByOU -OUDistinguishedNames @('OU=Workstations,DC=corp,DC=local')).Data
```

$tested = Test-MachineConnectivity -Machines $machines
$tested.Data | Where-Object IsOnline | Format-Table Hostname, WinRMStatus

## PARAMETERS

### -Machines
Array of machine objects to test.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestWinRM
Also test WinRM connectivity.
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

### -TimeoutSeconds
Timeout for each test in seconds.
Default: 5

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result object with Success, Data (tested machines), and Error.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
