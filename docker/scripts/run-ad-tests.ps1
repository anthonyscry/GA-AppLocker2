#Requires -Version 7.0
<#
.SYNOPSIS
    Runs AD integration tests against the Docker Samba AD DC.

.DESCRIPTION
    This script runs inside the PowerShell test container and executes
    AD-related tests against the Samba AD DC container.

.NOTES
    Environment variables required:
    - AD_SERVER: IP or hostname of the AD server
    - AD_DOMAIN: AD domain name (e.g., YOURLAB.LOCAL)
    - AD_USER: Admin username
    - AD_PASSWORD: Admin password
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  GA-AppLocker AD Integration Tests" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Get environment variables
$adServer = $env:AD_SERVER
$adDomain = $env:AD_DOMAIN
$adUser = $env:AD_USER
$adPassword = $env:AD_PASSWORD

Write-Host "AD Server:  $adServer" -ForegroundColor Gray
Write-Host "AD Domain:  $adDomain" -ForegroundColor Gray
Write-Host "AD User:    $adUser" -ForegroundColor Gray
Write-Host ""

# Wait for AD to be ready
Write-Host "Waiting for AD server to be ready..." -ForegroundColor Yellow
$maxRetries = 30
$retryCount = 0
$adReady = $false

while (-not $adReady -and $retryCount -lt $maxRetries) {
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($adServer, 389)
        $tcpClient.Close()
        $adReady = $true
        Write-Host "[OK] AD server is responding on LDAP port 389" -ForegroundColor Green
    }
    catch {
        $retryCount++
        Write-Host "  Attempt $retryCount/$maxRetries - Waiting for LDAP..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

if (-not $adReady) {
    Write-Host "[FAIL] AD server did not respond after $maxRetries attempts" -ForegroundColor Red
    exit 1
}

# Install LDAP module for PowerShell Core
Write-Host "`nInstalling LDAP tools..." -ForegroundColor Yellow
try {
    # On Linux, we use ldapsearch command-line tool
    apt-get update -qq 2>/dev/null
    apt-get install -y -qq ldap-utils 2>/dev/null
    Write-Host "[OK] LDAP tools installed" -ForegroundColor Green
}
catch {
    Write-Host "[WARN] Could not install ldap-utils: $_" -ForegroundColor Yellow
}

# Test 1: LDAP Connection
Write-Host "`n--- Test 1: LDAP Connection ---" -ForegroundColor Cyan
try {
    $ldapResult = & ldapsearch -x -H "ldap://$adServer" -b "DC=yourlab,DC=local" -D "$adUser@$adDomain" -w $adPassword "(objectClass=domain)" dn 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] LDAP connection successful" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] LDAP connection failed: $ldapResult" -ForegroundColor Red
    }
}
catch {
    Write-Host "[FAIL] LDAP test error: $_" -ForegroundColor Red
}

# Test 2: Query OUs
Write-Host "`n--- Test 2: Query Organizational Units ---" -ForegroundColor Cyan
try {
    $ouResult = & ldapsearch -x -H "ldap://$adServer" -b "DC=yourlab,DC=local" -D "$adUser@$adDomain" -w $adPassword "(objectClass=organizationalUnit)" dn 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ouCount = ($ouResult | Select-String "^dn:").Count
        Write-Host "[PASS] Found $ouCount OUs" -ForegroundColor Green
        $ouResult | Select-String "^dn:" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "[FAIL] OU query failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "[FAIL] OU test error: $_" -ForegroundColor Red
}

# Test 3: Query Computers
Write-Host "`n--- Test 3: Query Computers ---" -ForegroundColor Cyan
try {
    $compResult = & ldapsearch -x -H "ldap://$adServer" -b "DC=yourlab,DC=local" -D "$adUser@$adDomain" -w $adPassword "(objectClass=computer)" cn 2>&1
    if ($LASTEXITCODE -eq 0) {
        $compCount = ($compResult | Select-String "^cn:").Count
        Write-Host "[PASS] Found $compCount computers" -ForegroundColor Green
        $compResult | Select-String "^cn:" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "[FAIL] Computer query failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "[FAIL] Computer test error: $_" -ForegroundColor Red
}

# Test 4: Query Users
Write-Host "`n--- Test 4: Query Users ---" -ForegroundColor Cyan
try {
    $userResult = & ldapsearch -x -H "ldap://$adServer" -b "DC=yourlab,DC=local" -D "$adUser@$adDomain" -w $adPassword "(&(objectClass=user)(objectCategory=person))" sAMAccountName 2>&1
    if ($LASTEXITCODE -eq 0) {
        $userCount = ($userResult | Select-String "^sAMAccountName:").Count
        Write-Host "[PASS] Found $userCount users" -ForegroundColor Green
        $userResult | Select-String "^sAMAccountName:" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "[FAIL] User query failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "[FAIL] User test error: $_" -ForegroundColor Red
}

# Test 5: Query Groups
Write-Host "`n--- Test 5: Query Security Groups ---" -ForegroundColor Cyan
try {
    $groupResult = & ldapsearch -x -H "ldap://$adServer" -b "DC=yourlab,DC=local" -D "$adUser@$adDomain" -w $adPassword "(objectClass=group)" cn 2>&1
    if ($LASTEXITCODE -eq 0) {
        $groupCount = ($groupResult | Select-String "^cn:").Count
        Write-Host "[PASS] Found $groupCount groups" -ForegroundColor Green
        $groupResult | Select-String "^cn:" | Select-Object -First 10 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "[FAIL] Group query failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "[FAIL] Group test error: $_" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AD Integration Tests Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
