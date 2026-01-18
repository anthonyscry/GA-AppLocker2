Import-Module './GA-AppLocker/GA-AppLocker.psd1' -Force

Write-Host 'Testing LDAP Basic auth without SSL warning...' -ForegroundColor Cyan
$cred = New-Object PSCredential('test', (ConvertTo-SecureString 'test' -AsPlainText -Force))
$result = Get-LdapConnection -Server 'localhost' -Port 10389 -Credential $cred -ErrorAction SilentlyContinue

Write-Host ''
Write-Host 'Result: ' -NoNewline
if (-not $result) {
    Write-Host 'Connection failed (expected - no server)' -ForegroundColor Yellow
} else {
    Write-Host 'Connected' -ForegroundColor Green
}
