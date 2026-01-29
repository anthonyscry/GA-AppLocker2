---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-RuleStatus

## SYNOPSIS
Updates a rule's status.

## SYNTAX

```
Set-RuleStatus [-Id] <String> [-Status] <String> [<CommonParameters>]
```

## DESCRIPTION
Changes the approval status of a rule (traffic light workflow).

## EXAMPLES

### EXAMPLE 1
```
Set-RuleStatus -Id '12345678-...' -Status Approved
```

## PARAMETERS

### -Id
Rule GUID to update.

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
New status: Pending, Approved, Rejected, Review.

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

### [PSCustomObject] Result with Success and updated rule.
## NOTES

## RELATED LINKS
