---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-EmailNotifyOn

## SYNOPSIS
Configures which events trigger email notifications.

## SYNTAX

```
Set-EmailNotifyOn [[-PolicyDeployed] <Boolean>] [[-RulesApproved] <Boolean>] [[-ScanCompleted] <Boolean>]
 [[-SystemErrors] <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Configures which events trigger email notifications.
Persists the change to the GA-AppLocker data store.

## EXAMPLES

### EXAMPLE 1
```
Set-EmailNotifyOn -PolicyDeployed $true -SystemErrors $true
```

## PARAMETERS

### -PolicyDeployed
Notify when a policy is deployed.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RulesApproved
Notify when rules are approved.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScanCompleted
Notify when a scan completes.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SystemErrors
Notify on system errors.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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
