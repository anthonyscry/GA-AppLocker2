---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# New-PublisherRule

## SYNOPSIS
Creates a new AppLocker Publisher rule.

## SYNTAX

```
New-PublisherRule [-PublisherName] <String> [[-ProductName] <String>] [[-BinaryName] <String>]
 [[-MinVersion] <String>] [[-MaxVersion] <String>] [[-Action] <String>] [[-CollectionType] <String>]
 [[-Name] <String>] [[-Description] <String>] [[-UserOrGroupSid] <String>] [[-Status] <String>]
 [[-SourceArtifactId] <String>] [[-GroupName] <String>] [[-GroupSuggestion] <PSObject>] [-Save]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a publisher-based AppLocker rule using digital signature information.
Publisher rules are the most flexible as they allow updates to pass through
as long as they're signed by the same publisher.

## EXAMPLES

### EXAMPLE 1
```
New-PublisherRule -PublisherName 'O=MICROSOFT CORPORATION' -ProductName '*' -Action Allow
```

### EXAMPLE 2
```
New-PublisherRule -PublisherName 'O=ADOBE INC.' -ProductName 'ADOBE READER' -MinVersion '11.0.0.0'
```

## PARAMETERS

### -PublisherName
The publisher/signer certificate subject or O= field.

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

### -ProductName
The product name.
Use '*' for any product.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -BinaryName
The binary file name.
Use '*' for any binary.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinVersion
Minimum version (inclusive).
Default is '*' (any).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxVersion
Maximum version (inclusive).
Default is '*' (any).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: *
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
Position: 6
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
Position: 7
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
Position: 8
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
Position: 9
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
Position: 10
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
Position: 11
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
Position: 12
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
Position: 13
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
Position: 14
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
