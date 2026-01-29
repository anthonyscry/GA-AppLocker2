---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Send-AppLockerNotification

## SYNOPSIS
Sends an email notification.

## SYNTAX

```
Send-AppLockerNotification [-Subject] <String> [-Body] <String> [[-EventType] <String>] [[-Priority] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Sends an email notification.
Uses the configured email transport settings.

## EXAMPLES

### EXAMPLE 1
```
Send-AppLockerNotification -Subject 'Policy Deployed' -Body 'Policy XYZ was deployed successfully.' -EventType 'PolicyDeployed'
```

## PARAMETERS

### -Subject
Email subject line.

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

### -Body
Email body content.

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

### -EventType
Type of event: PolicyDeployed, RulesApproved, ScanCompleted, SystemErrors.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: General
Accept pipeline input: False
Accept wildcard characters: False
```

### -Priority
Email priority: Low, Normal, High.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Normal
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
