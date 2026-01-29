---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Remove-Rule

## SYNOPSIS
Removes a rule from storage.

## SYNTAX

```
Remove-Rule [-Id] <String> [-Force] [<CommonParameters>]
```

## DESCRIPTION
Deletes an AppLocker rule from local storage.

## EXAMPLES

### EXAMPLE 1
```
Remove-Rule -Id '12345678-...'
```

## PARAMETERS

### -Id
Rule GUID to delete.

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
Skip confirmation prompt.

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

### [PSCustomObject] Result with Success.
## NOTES

## RELATED LINKS
