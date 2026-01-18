# Run AD integration tests
$ErrorActionPreference = 'Stop'

Write-Host "`n=== Running AD Integration Tests ===" -ForegroundColor Cyan

# First verify AD is up
$adServer = '127.0.0.1'
$adPort = 10389
$adDomain = 'YOURLAB.LOCAL'
$adUser = 'Administrator'
$adPassword = 'P@ssw0rd123!'
$baseDN = 'DC=yourlab,DC=local'

Write-Host "`n1. Testing TCP connectivity to $adServer`:$adPort..." -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($adServer, $adPort)
    $tcp.Close()
    Write-Host "   [PASS] Port is open" -ForegroundColor Green
}
catch {
    Write-Host "   [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Testing LDAP authentication..." -ForegroundColor Yellow
try {
    $ldapPath = "LDAP://$adServer`:$adPort/$baseDN"
    $de = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, "$adUser@$adDomain", $adPassword)
    $null = $de.distinguishedName
    $de.Dispose()
    Write-Host "   [PASS] Authentication successful" -ForegroundColor Green
}
catch {
    Write-Host "   [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n3. Testing OU enumeration..." -ForegroundColor Yellow
try {
    $ldapPath = "LDAP://$adServer`:$adPort/$baseDN"
    $de = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, "$adUser@$adDomain", $adPassword)
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($de)
    $searcher.Filter = "(objectClass=organizationalUnit)"
    $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
    $results = $searcher.FindAll()
    
    $ous = @()
    foreach ($result in $results) {
        $ous += $result.Properties["name"][0]
    }
    
    Write-Host "   [PASS] Found $($ous.Count) OUs: $($ous -join ', ')" -ForegroundColor Green
    
    $results.Dispose()
    $searcher.Dispose()
    $de.Dispose()
}
catch {
    Write-Host "   [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n4. Testing computer enumeration..." -ForegroundColor Yellow
try {
    $ldapPath = "LDAP://$adServer`:$adPort/$baseDN"
    $de = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, "$adUser@$adDomain", $adPassword)
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($de)
    $searcher.Filter = "(objectClass=computer)"
    $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
    $results = $searcher.FindAll()
    
    $computers = @()
    foreach ($result in $results) {
        $computers += $result.Properties["cn"][0]
    }
    
    Write-Host "   [PASS] Found $($computers.Count) computers: $($computers -join ', ')" -ForegroundColor Green
    
    $results.Dispose()
    $searcher.Dispose()
    $de.Dispose()
}
catch {
    Write-Host "   [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n5. Testing group enumeration..." -ForegroundColor Yellow
try {
    $ldapPath = "LDAP://$adServer`:$adPort/$baseDN"
    $de = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, "$adUser@$adDomain", $adPassword)
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($de)
    $searcher.Filter = "(&(objectClass=group)(cn=AppLocker*))"
    $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
    $results = $searcher.FindAll()
    
    $groups = @()
    foreach ($result in $results) {
        $groups += $result.Properties["cn"][0]
    }
    
    Write-Host "   [PASS] Found $($groups.Count) AppLocker groups: $($groups -join ', ')" -ForegroundColor Green
    
    $results.Dispose()
    $searcher.Dispose()
    $de.Dispose()
}
catch {
    Write-Host "   [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== All AD Integration Tests Passed! ===" -ForegroundColor Green
