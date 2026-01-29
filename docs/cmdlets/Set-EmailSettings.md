---
external help file: GA-AppLocker-help.xml
Module Name: GA-AppLocker
online version:
schema: 2.0.0
---

# Set-EmailSettings

## SYNOPSIS
Configures email notification settings.

## SYNTAX

```
Set-EmailSettings [[-SmtpServer] <String>] [[-SmtpPort] <Int32>] [-UseSsl] [[-FromAddress] <String>]
 [[-ToAddresses] <String[]>] [[-Credential] <PSCredential>] [-Enabled] [<CommonParameters>]
```

## DESCRIPTION
Configures email notification settings.
Persists the change to the GA-AppLocker data store.

## EXAMPLES

### EXAMPLE 1
```
Set-EmailSettings -SmtpServer 'mail.corp.local' -FromAddress 'applocker@corp.local' -ToAddresses @('admin@corp.local')
```

## PARAMETERS

### -SmtpServer
SMTP server hostname or IP address.

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

### -SmtpPort
SMTP port (default: 25).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 25
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseSsl
Use SSL/TLS for SMTP connection.

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

### -FromAddress
Email address to send from.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToAddresses
Array of email addresses to send notifications to.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
PSCredential for SMTP authentication (optional).

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Enabled
Enable or disable email notifications.

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

## NOTES

## RELATED LINKS
