#Requires -Version 5.1
<#
.SYNOPSIS
    Manages the Docker-based AD test environment for GA-AppLocker.

.DESCRIPTION
    Starts, stops, and manages the Samba AD DC Docker container for testing
    AD integration without requiring a real domain environment.

.PARAMETER Action
    The action to perform: Start, Stop, Status, Restart, Logs, Test

.PARAMETER Wait
    Wait for AD to be fully ready (checks LDAP connectivity).

.PARAMETER Timeout
    Timeout in seconds when waiting for AD to be ready (default: 180).

.EXAMPLE
    .\Start-ADTestEnvironment.ps1 -Action Start -Wait
    Starts the AD environment and waits for it to be ready.

.EXAMPLE
    .\Start-ADTestEnvironment.ps1 -Action Stop
    Stops the AD environment.

.EXAMPLE
    .\Start-ADTestEnvironment.ps1 -Action Test
    Runs a quick connectivity test against the AD environment.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'Stop', 'Status', 'Restart', 'Logs', 'Test', 'Reset')]
    [string]$Action,

    [Parameter()]
    [switch]$Wait,

    [Parameter()]
    [int]$Timeout = 180
)

$ErrorActionPreference = 'Stop'
$dockerDir = $PSScriptRoot

# AD Configuration (using non-standard ports to avoid Windows conflicts)
$adConfig = @{
    Server   = '127.0.0.1'
    Port     = 10389  # Mapped from container's 389
    Domain   = 'YOURLAB.LOCAL'
    User     = 'Administrator'
    Password = 'P@ssw0rd123!'
    BaseDN   = 'DC=yourlab,DC=local'
}

function Test-DockerAvailable {
    try {
        $null = docker --version 2>&1
        return $?
    }
    catch {
        return $false
    }
}

function Test-ADConnectivity {
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($adConfig.Server, $adConfig.Port)
        $tcpClient.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Test-ADAuthentication {
    try {
        $ldapPath = "LDAP://$($adConfig.Server):$($adConfig.Port)/$($adConfig.BaseDN)"
        $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
            $ldapPath,
            "$($adConfig.User)@$($adConfig.Domain)",
            $adConfig.Password
        )
        $null = $directoryEntry.distinguishedName
        $directoryEntry.Dispose()
        return $true
    }
    catch {
        return $false
    }
}

function Wait-ADReady {
    param([int]$TimeoutSeconds = 180)
    
    Write-Host "Waiting for AD to be ready (timeout: ${TimeoutSeconds}s)..." -ForegroundColor Yellow
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $elapsed = [math]::Round($stopwatch.Elapsed.TotalSeconds)
        
        # Check LDAP port
        if (-not (Test-ADConnectivity)) {
            Write-Host "  [$elapsed s] Waiting for LDAP port..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
            continue
        }
        
        # Check authentication
        if (-not (Test-ADAuthentication)) {
            Write-Host "  [$elapsed s] LDAP up, waiting for authentication..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
            continue
        }
        
        Write-Host "[OK] AD is ready! (took $elapsed seconds)" -ForegroundColor Green
        return $true
    }
    
    Write-Host "[FAIL] Timeout waiting for AD to be ready" -ForegroundColor Red
    return $false
}

# Check Docker availability
if (-not (Test-DockerAvailable)) {
    Write-Host "[ERROR] Docker is not available. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Execute action
switch ($Action) {
    'Start' {
        Write-Host "`n=== Starting AD Test Environment ===" -ForegroundColor Cyan
        Push-Location $dockerDir
        try {
            docker-compose up -d
            if ($Wait) {
                Start-Sleep -Seconds 10  # Give container time to start
                $ready = Wait-ADReady -TimeoutSeconds $Timeout
                if (-not $ready) {
                    Write-Host "AD may still be initializing. Check logs with: .\Start-ADTestEnvironment.ps1 -Action Logs" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "`nAD environment starting. Use -Wait to wait for readiness." -ForegroundColor Yellow
                Write-Host "Or check status with: .\Start-ADTestEnvironment.ps1 -Action Status" -ForegroundColor Gray
            }
        }
        finally {
            Pop-Location
        }
    }
    
    'Stop' {
        Write-Host "`n=== Stopping AD Test Environment ===" -ForegroundColor Cyan
        Push-Location $dockerDir
        try {
            docker-compose down
            Write-Host "[OK] AD environment stopped" -ForegroundColor Green
        }
        finally {
            Pop-Location
        }
    }
    
    'Status' {
        Write-Host "`n=== AD Test Environment Status ===" -ForegroundColor Cyan
        
        # Container status
        Push-Location $dockerDir
        try {
            $containers = docker-compose ps --format json 2>$null | ConvertFrom-Json
            if ($containers) {
                foreach ($c in $containers) {
                    $status = if ($c.State -eq 'running') { 'Running' } else { $c.State }
                    $color = if ($c.State -eq 'running') { 'Green' } else { 'Yellow' }
                    Write-Host "Container: $($c.Name) - $status" -ForegroundColor $color
                }
            }
            else {
                docker-compose ps
            }
        }
        finally {
            Pop-Location
        }
        
        Write-Host ""
        
        # Connectivity check
        if (Test-ADConnectivity) {
            Write-Host "LDAP Port 389: " -NoNewline
            Write-Host "OPEN" -ForegroundColor Green
            
            if (Test-ADAuthentication) {
                Write-Host "Authentication:  " -NoNewline
                Write-Host "OK" -ForegroundColor Green
            }
            else {
                Write-Host "Authentication:  " -NoNewline
                Write-Host "FAILED" -ForegroundColor Red
            }
        }
        else {
            Write-Host "LDAP Port 389: " -NoNewline
            Write-Host "CLOSED" -ForegroundColor Red
        }
        
        Write-Host "`nAD Configuration:" -ForegroundColor Gray
        Write-Host "  Server:   $($adConfig.Server):$($adConfig.Port)" -ForegroundColor Gray
        Write-Host "  Domain:   $($adConfig.Domain)" -ForegroundColor Gray
        Write-Host "  User:     $($adConfig.User)" -ForegroundColor Gray
    }
    
    'Restart' {
        Write-Host "`n=== Restarting AD Test Environment ===" -ForegroundColor Cyan
        Push-Location $dockerDir
        try {
            docker-compose restart
            if ($Wait) {
                Start-Sleep -Seconds 10
                Wait-ADReady -TimeoutSeconds $Timeout
            }
        }
        finally {
            Pop-Location
        }
    }
    
    'Logs' {
        Push-Location $dockerDir
        try {
            docker-compose logs -f --tail=100 samba-ad
        }
        finally {
            Pop-Location
        }
    }
    
    'Test' {
        Write-Host "`n=== AD Connectivity Test ===" -ForegroundColor Cyan
        
        Write-Host "`n1. LDAP Port Check..." -ForegroundColor Yellow
        if (Test-ADConnectivity) {
            Write-Host "   [PASS] LDAP port 389 is open" -ForegroundColor Green
        }
        else {
            Write-Host "   [FAIL] Cannot connect to LDAP port 389" -ForegroundColor Red
            Write-Host "   Make sure AD is running: .\Start-ADTestEnvironment.ps1 -Action Start -Wait" -ForegroundColor Gray
            exit 1
        }
        
        Write-Host "`n2. LDAP Authentication..." -ForegroundColor Yellow
        if (Test-ADAuthentication) {
            Write-Host "   [PASS] Successfully authenticated to AD" -ForegroundColor Green
        }
        else {
            Write-Host "   [FAIL] Authentication failed" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "`n3. LDAP Query Test..." -ForegroundColor Yellow
        try {
            $ldapPath = "LDAP://$($adConfig.Server):$($adConfig.Port)/$($adConfig.BaseDN)"
            $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
                $ldapPath,
                "$($adConfig.User)@$($adConfig.Domain)",
                $adConfig.Password
            )
            
            $searcher = New-Object System.DirectoryServices.DirectorySearcher($directoryEntry)
            $searcher.Filter = "(objectClass=organizationalUnit)"
            $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
            
            $results = $searcher.FindAll()
            $ouCount = $results.Count
            $results.Dispose()
            $searcher.Dispose()
            $directoryEntry.Dispose()
            
            Write-Host "   [PASS] Found $ouCount OUs in directory" -ForegroundColor Green
        }
        catch {
            Write-Host "   [FAIL] LDAP query failed: $_" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "`n=== All Tests Passed ===" -ForegroundColor Green
    }
    
    'Reset' {
        Write-Host "`n=== Resetting AD Test Environment ===" -ForegroundColor Cyan
        Write-Host "This will destroy all data and recreate the AD environment." -ForegroundColor Yellow
        $confirm = Read-Host "Continue? (y/N)"
        if ($confirm -ne 'y') {
            Write-Host "Cancelled." -ForegroundColor Gray
            exit 0
        }
        
        Push-Location $dockerDir
        try {
            docker-compose down -v  # Remove volumes too
            docker-compose up -d
            if ($Wait) {
                Start-Sleep -Seconds 10
                Wait-ADReady -TimeoutSeconds $Timeout
            }
        }
        finally {
            Pop-Location
        }
    }
}
