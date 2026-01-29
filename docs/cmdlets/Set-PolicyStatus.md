---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-PolicyStatus

## SYNOPSIS
Updates the status of a policy.

## SYNTAX

```
Set-PolicyStatus [-PolicyId] <String> [-Status] <String> [<CommonParameters>]
```

## DESCRIPTION
Updates the status of a policy.
Persists the change to the local GA-AppLocker data store under %LOCALAPPDATA%\GA-AppLocker.

## EXAMPLES

### EXAMPLE 1
```
Set-PolicyStatus -PolicyId "abc123" -Status "Active"
```

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

### -Status
The new status: Draft, Active, Deployed, or Archived.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
