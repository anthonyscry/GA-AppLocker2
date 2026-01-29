---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Invoke-RuleBatchOperation

## SYNOPSIS
Performs a batch operation on multiple rules.

## SYNTAX

```
Invoke-RuleBatchOperation [-RuleIds] <String[]> [-Operation] <String> [[-Parameters] <Hashtable>]
 [<CommonParameters>]
```

## DESCRIPTION
Executes an operation on multiple rules efficiently, with single
cache invalidation and event at the end.

## EXAMPLES

### EXAMPLE 1
```
Invoke-RuleBatchOperation -RuleIds @('r1','r2','r3') -Operation 'UpdateStatus' -Parameters @{ Status = 'Approved' }
```

### EXAMPLE 2
```
Invoke-RuleBatchOperation -RuleIds $duplicateIds -Operation 'Delete'
```

## PARAMETERS

### -RuleIds
Array of rule IDs to operate on.

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

### -Operation
The operation to perform: 'UpdateStatus', 'Delete'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Parameters
Hashtable of operation parameters.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with success count and errors
## NOTES

## RELATED LINKS
