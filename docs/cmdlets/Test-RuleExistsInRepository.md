---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Test-RuleExistsInRepository

## SYNOPSIS
Checks if a rule exists in the repository.

## SYNTAX

### ById
```
Test-RuleExistsInRepository [-RuleId <String>] [<CommonParameters>]
```

### ByHash
```
Test-RuleExistsInRepository [-Hash <String>] [<CommonParameters>]
```

## DESCRIPTION
Efficiently checks for rule existence without loading the full rule.

## EXAMPLES

### EXAMPLE 1
```
if (Test-RuleExistsInRepository -RuleId 'rule-123') { ... }
```

### EXAMPLE 2
```
if (Test-RuleExistsInRepository -Hash 'ABC123...') { ... }
```

## PARAMETERS

### -RuleId
The rule ID to check.

```yaml
Type: String
Parameter Sets: ById
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hash
Alternative: check by hash value.

```yaml
Type: String
Parameter Sets: ByHash
Aliases:

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

### [bool] True if rule exists
## NOTES

## RELATED LINKS
