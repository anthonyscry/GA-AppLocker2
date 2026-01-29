---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Remove-Policy

## SYNOPSIS
Removes a policy.

## SYNTAX

```
Remove-Policy [-PolicyId] <String> [-Force] [<CommonParameters>]
```

## DESCRIPTION
Removes a policy.

## EXAMPLES

### EXAMPLE 1
```
Remove-Policy -PolicyId "abc123"
```

## PARAMETERS

### -PolicyId
The unique identifier of the policy to remove.

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

### -Force
Force removal even if policy is deployed.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
