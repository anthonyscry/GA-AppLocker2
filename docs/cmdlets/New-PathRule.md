---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-PathRule

## SYNOPSIS
Creates a new AppLocker Path rule.

## SYNTAX

```
New-PathRule [-Path] <String> [[-Action] <String>] [[-CollectionType] <String>] [[-Name] <String>]
 [[-Description] <String>] [[-UserOrGroupSid] <String>] [[-Status] <String>] [[-SourceArtifactId] <String>]
 [[-GroupName] <String>] [[-GroupSuggestion] <PSObject>] [-Save] [<CommonParameters>]
```

## DESCRIPTION
Creates a path-based AppLocker rule using file or folder paths.
Path rules are the least secure but most convenient for allowing
entire directories like Program Files.

## EXAMPLES

### EXAMPLE 1
```
New-PathRule -Path '%PROGRAMFILES%\*' -Action Allow
```

### EXAMPLE 2
```
New-PathRule -Path 'C:\CustomApp\*.exe' -Action Allow -CollectionType Exe
```

## PARAMETERS

### -Path
The file or folder path.
Supports wildcards and variables:
- * matches any characters
- %OSDRIVE% = C:
- %WINDIR% = C:\Windows
- %SYSTEM32% = C:\Windows\System32
- %PROGRAMFILES% = C:\Program Files
- %REMOVABLE% = Removable drives
- %HOT% = Hot-plugged drives

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

### -Action
Rule action: Allow or Deny.
Default is Allow.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Allow
Accept pipeline input: False
Accept wildcard characters: False
```

### -CollectionType
AppLocker collection: Exe, Dll, Msi, Script, Appx.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Exe
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Display name for the rule.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Description of the rule.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserOrGroupSid
SID of user or group this rule applies to.
Default is Everyone (S-1-1-0).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: S-1-1-0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Rule status for traffic light workflow: Pending, Approved, Rejected, Review.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: Pending
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceArtifactId
ID of the artifact this rule was generated from (for tracking).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupName
{{ Fill GroupName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupSuggestion
{{ Fill GroupSuggestion Description }}

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Save
{{ Fill Save Description }}

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

### [PSCustomObject] The created rule object.
## NOTES

## RELATED LINKS
