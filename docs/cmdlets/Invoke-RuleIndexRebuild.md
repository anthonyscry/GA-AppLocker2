---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Invoke-RuleIndexRebuild

## SYNOPSIS
Manually triggers an index rebuild.

## SYNTAX

```
Invoke-RuleIndexRebuild [<CommonParameters>]
```

## DESCRIPTION
Forces an immediate index rebuild without waiting for file changes.
Useful after bulk operations or when the index appears stale.

## EXAMPLES

### EXAMPLE 1
```
Invoke-RuleIndexRebuild
```

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result from Rebuild-RulesIndex.
## NOTES

## RELATED LINKS
