---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-DeploymentJob

## SYNOPSIS
Creates a new deployment job for a policy.

## SYNTAX

```
New-DeploymentJob [-PolicyId] <String> [-GPOName] <String> [[-TargetOUs] <String[]>] [[-Schedule] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a deployment job that tracks the deployment of
an AppLocker policy to a GPO.

## EXAMPLES

### EXAMPLE 1
```
New-DeploymentJob -PolicyId "abc123" -GPOName "AppLocker-Workstations"
```

## PARAMETERS

### -PolicyId
The ID of the policy to deploy.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GPOName
The name of the target GPO.

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

### -TargetOUs
Optional array of OU distinguished names to link the GPO to.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -Schedule
When to execute: 'Immediate', 'Scheduled', or 'Manual'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Manual
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
