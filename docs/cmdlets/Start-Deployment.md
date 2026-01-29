---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Start-Deployment

## SYNOPSIS
Starts a deployment job.

## SYNTAX

```
Start-Deployment [-JobId] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Executes the deployment process:
1.
Export policy to XML
2.
Check/create GPO
3.
Import policy to GPO
4.
Link GPO to OUs if specified

## EXAMPLES

### EXAMPLE 1
```
Start-Deployment -JobId "abc123"
```

## PARAMETERS

### -JobId
The ID of the deployment job to start.

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

### -WhatIf
Show what would happen without making changes.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
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
