---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-PolicyTarget

## SYNOPSIS
Sets the target OUs or GPO for a policy.

## SYNTAX

```
Set-PolicyTarget [-PolicyId] <String> [[-TargetOUs] <String[]>] [[-TargetGPO] <String>] [<CommonParameters>]
```

## DESCRIPTION
Sets the target OUs or GPO for a policy.
Persists the change to the local GA-AppLocker data store under %LOCALAPPDATA%\GA-AppLocker.

## EXAMPLES

### EXAMPLE 1
```
Set-PolicyTarget -PolicyId "abc123" -TargetOUs @("OU=Workstations,DC=domain,DC=com")
```

Set-PolicyTarget -PolicyId "abc123" -TargetGPO "AppLocker-Workstations"

## PARAMETERS

### -PolicyId
The unique identifier of the policy.

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

### -TargetOUs
Array of OU distinguished names to target.

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

### -TargetGPO
The name of the GPO to deploy to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
