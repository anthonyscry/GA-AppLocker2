---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Invoke-WithRetry

## SYNOPSIS
Executes a script block with automatic retry logic for transient failures.

## SYNTAX

```
Invoke-WithRetry [-ScriptBlock] <ScriptBlock> [[-MaxRetries] <Int32>] [[-InitialDelayMs] <Int32>]
 [[-MaxDelayMs] <Int32>] [-UseExponentialBackoff] [[-TransientErrorPatterns] <String[]>]
 [[-OperationName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Wraps a script block execution with configurable retry logic, including
exponential backoff and filtering for transient vs permanent errors.
Particularly useful for WinRM and network operations.

## EXAMPLES

### EXAMPLE 1
```
Invoke-WithRetry -ScriptBlock { Invoke-Command -ComputerName 'Server01' -ScriptBlock { Get-Process } }
```

### EXAMPLE 2
```
Invoke-WithRetry -ScriptBlock { Test-WSMan -ComputerName 'Server01' } -MaxRetries 5 -OperationName 'WinRM Test'
```

## PARAMETERS

### -ScriptBlock
The script block to execute.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxRetries
Maximum number of retry attempts.
Default is 3.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitialDelayMs
Initial delay between retries in milliseconds.
Default is 1000.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxDelayMs
Maximum delay between retries in milliseconds.
Default is 10000.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 10000
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseExponentialBackoff
If true, delay doubles after each retry.
Default is true.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -TransientErrorPatterns
Array of regex patterns to identify transient errors that should trigger retry.
Default includes common WinRM and network error patterns.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: @(
            'The WinRM client cannot process the request',
            'The client cannot connect to the destination',
            'WinRM cannot complete the operation',
            'The network path was not found',
            'Access is denied',
            'The RPC server is unavailable',
            'The remote computer is not available',
            'A connection attempt failed',
            'The operation has timed out',
            'The semaphore timeout period has expired',
            'The network name cannot be found',
            'The server is not operational'
        )
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperationName
Name of the operation for logging purposes.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: Operation
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns the result of the successful script block execution, or throws if all retries exhausted.
## NOTES
Author: GA-AppLocker Team
Version: 1.0.0

## RELATED LINKS
