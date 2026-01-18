# Quick test for AD connectivity
$port = 10389
$server = '127.0.0.1'

Write-Host "Testing connection to $server`:$port..."

try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($server, $port)
    Write-Host "[OK] Port $port is OPEN" -ForegroundColor Green
    $tcp.Close()
}
catch {
    Write-Host "[FAIL] Port $port is CLOSED: $($_.Exception.Message)" -ForegroundColor Red
}

# Also try LDAP bind
Write-Host "`nTesting LDAP authentication..."
try {
    $ldapPath = "LDAP://$server`:$port/DC=yourlab,DC=local"
    $de = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, "Administrator@YOURLAB.LOCAL", "P@ssw0rd123!")
    $null = $de.distinguishedName
    Write-Host "[OK] LDAP authentication successful" -ForegroundColor Green
    $de.Dispose()
}
catch {
    Write-Host "[FAIL] LDAP authentication failed: $($_.Exception.Message)" -ForegroundColor Red
}
