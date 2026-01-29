---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-HashRule

## SYNOPSIS
Creates a new AppLocker Hash rule.

## SYNTAX

```
New-HashRule [-Hash] <String> [-SourceFileName] <String> [[-SourceFileLength] <Int64>] [[-Action] <String>]
 [[-CollectionType] <String>] [[-Name] <String>] [[-Description] <String>] [[-UserOrGroupSid] <String>]
 [[-Status] <String>] [[-SourceArtifactId] <String>] [[-GroupName] <String>] [[-GroupSuggestion] <PSObject>]
 [-Save] [<CommonParameters>]
```

## DESCRIPTION
Creates a hash-based AppLocker rule using SHA256 file hash.
Hash rules are the most secure as they identify a specific file,
but require updates whenever the file changes.

## EXAMPLES

### EXAMPLE 1
```
New-HashRule -Hash 'ABC123...' -SourceFileName 'app.exe' -SourceFileLength 1234567
```

## PARAMETERS

### -Hash
The SHA256 hash of the file.

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

### -SourceFileName
Original file name.

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

### -SourceFileLength
File size in bytes.

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
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
Position: 4
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
Position: 5
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
Position: 6
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
Position: 7
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
Position: 8
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
Position: 9
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
Position: 10
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
Position: 11
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
Position: 12
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
