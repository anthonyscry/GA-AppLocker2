---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Start-RuleIndexWatcher

## SYNOPSIS
Starts monitoring the Rules directory for changes.

## SYNTAX

```
Start-RuleIndexWatcher [[-RulesPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
Creates a FileSystemWatcher that monitors the Rules JSON directory.
When files are added, modified, or deleted, it schedules an index rebuild
with debouncing to batch multiple rapid changes.

## EXAMPLES

### EXAMPLE 1
```
Start-RuleIndexWatcher
```

Starts watching the default Rules directory.

## PARAMETERS

### -RulesPath
Path to the Rules directory.
If not specified, uses the default data path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject] Result with Success status and watcher state.
## NOTES

## RELATED LINKS
