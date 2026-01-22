<#
.SYNOPSIS
    Fast query functions for rule lookups using SQLite indexes.
#>

function Find-RuleByHash {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Hash,
        
        [string]$CollectionType
    )
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) { return $null }
    
    # Normalize hash
    $cleanHash = $Hash -replace '^0x', ''
    $cleanHash = $cleanHash.ToUpper()
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        $sql = "SELECT PayloadJson FROM Rules WHERE Hash = @Hash"
        $params = @{ Hash = $cleanHash }
        
        if ($CollectionType) {
            $sql += " AND CollectionType = @CollectionType"
            $params.CollectionType = $CollectionType
        }
        
        $sql += " LIMIT 1;"
        
        $result = Invoke-SqliteScalar -Connection $conn -CommandText $sql -Parameters $params
        
        if ($result) {
            return $result | ConvertFrom-Json
        }
        return $null
    }
    finally {
        $conn.Close()
        $conn.Dispose()
    }
}

function Find-RuleByPublisher {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$PublisherName,
        
        [string]$ProductName,
        [string]$CollectionType
    )
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) { return $null }
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        $sql = "SELECT PayloadJson FROM Rules WHERE PublisherName = @PublisherName"
        $params = @{ PublisherName = $PublisherName }
        
        if ($ProductName) {
            $sql += " AND ProductName = @ProductName"
            $params.ProductName = $ProductName
        }
        if ($CollectionType) {
            $sql += " AND CollectionType = @CollectionType"
            $params.CollectionType = $CollectionType
        }
        
        $sql += " LIMIT 1;"
        
        $result = Invoke-SqliteScalar -Connection $conn -CommandText $sql -Parameters $params
        
        if ($result) {
            return $result | ConvertFrom-Json
        }
        return $null
    }
    finally {
        $conn.Close()
        $conn.Dispose()
    }
}

function Get-RuleCounts {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $result = [PSCustomObject]@{
        Success        = $false
        Total          = 0
        ByStatus       = @{}
        ByRuleType     = @{}
        ByCollection   = @{}
        Error          = $null
    }
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) {
        $result.Success = $true
        return $result
    }
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        # Total count
        $result.Total = [int](Invoke-SqliteScalar -Connection $conn -CommandText "SELECT COUNT(*) FROM Rules;")
        
        # By Status
        $statusRows = Invoke-SqliteQuery -Connection $conn -CommandText "SELECT Status, COUNT(*) as Count FROM Rules GROUP BY Status;"
        foreach ($row in $statusRows) {
            $result.ByStatus[$row.Status] = [int]$row.Count
        }
        
        # By RuleType
        $typeRows = Invoke-SqliteQuery -Connection $conn -CommandText "SELECT RuleType, COUNT(*) as Count FROM Rules GROUP BY RuleType;"
        foreach ($row in $typeRows) {
            $result.ByRuleType[$row.RuleType] = [int]$row.Count
        }
        
        # By CollectionType
        $collRows = Invoke-SqliteQuery -Connection $conn -CommandText "SELECT CollectionType, COUNT(*) as Count FROM Rules GROUP BY CollectionType;"
        foreach ($row in $collRows) {
            $result.ByCollection[$row.CollectionType] = [int]$row.Count
        }
        
        $result.Success = $true
    }
    catch {
        $result.Error = "Failed to get counts: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    finally {
        $conn.Close()
        $conn.Dispose()
    }
    
    return $result
}

function Get-DuplicateRules {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [ValidateSet('Hash', 'Publisher', 'Path', 'All')]
        [string]$RuleType = 'All'
    )
    
    $result = [PSCustomObject]@{
        Success          = $false
        DuplicateGroups  = @()
        HashDuplicates   = 0
        PublisherDuplicates = 0
        PathDuplicates   = 0
        TotalDuplicates  = 0
        Error            = $null
    }
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) {
        $result.Success = $true
        return $result
    }
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        $groups = [System.Collections.Generic.List[PSCustomObject]]::new()
        
        # Find Hash duplicates
        if ($RuleType -eq 'Hash' -or $RuleType -eq 'All') {
            $sql = @"
SELECT Hash, CollectionType, COUNT(*) as DupeCount, GROUP_CONCAT(Id) as RuleIds
FROM Rules 
WHERE RuleType = 'Hash' AND Hash IS NOT NULL
GROUP BY Hash, CollectionType
HAVING COUNT(*) > 1
ORDER BY DupeCount DESC;
"@
            $rows = Invoke-SqliteQuery -Connection $conn -CommandText $sql
            foreach ($row in $rows) {
                $result.HashDuplicates += ($row.DupeCount - 1)
                $groups.Add([PSCustomObject]@{
                    Type = 'Hash'
                    Key = $row.Hash
                    CollectionType = $row.CollectionType
                    Count = [int]$row.DupeCount
                    RuleIds = $row.RuleIds -split ','
                })
            }
        }
        
        # Find Publisher duplicates
        if ($RuleType -eq 'Publisher' -or $RuleType -eq 'All') {
            $sql = @"
SELECT PublisherName, ProductName, CollectionType, COUNT(*) as DupeCount, GROUP_CONCAT(Id) as RuleIds
FROM Rules 
WHERE RuleType = 'Publisher' AND PublisherName IS NOT NULL
GROUP BY PublisherName, ProductName, CollectionType
HAVING COUNT(*) > 1
ORDER BY DupeCount DESC;
"@
            $rows = Invoke-SqliteQuery -Connection $conn -CommandText $sql
            foreach ($row in $rows) {
                $result.PublisherDuplicates += ($row.DupeCount - 1)
                $groups.Add([PSCustomObject]@{
                    Type = 'Publisher'
                    Key = "$($row.PublisherName)|$($row.ProductName)"
                    CollectionType = $row.CollectionType
                    Count = [int]$row.DupeCount
                    RuleIds = $row.RuleIds -split ','
                })
            }
        }
        
        # Find Path duplicates
        if ($RuleType -eq 'Path' -or $RuleType -eq 'All') {
            $sql = @"
SELECT Path, CollectionType, COUNT(*) as DupeCount, GROUP_CONCAT(Id) as RuleIds
FROM Rules 
WHERE RuleType = 'Path' AND Path IS NOT NULL
GROUP BY Path, CollectionType
HAVING COUNT(*) > 1
ORDER BY DupeCount DESC;
"@
            $rows = Invoke-SqliteQuery -Connection $conn -CommandText $sql
            foreach ($row in $rows) {
                $result.PathDuplicates += ($row.DupeCount - 1)
                $groups.Add([PSCustomObject]@{
                    Type = 'Path'
                    Key = $row.Path
                    CollectionType = $row.CollectionType
                    Count = [int]$row.DupeCount
                    RuleIds = $row.RuleIds -split ','
                })
            }
        }
        
        $result.DuplicateGroups = $groups.ToArray()
        $result.TotalDuplicates = $result.HashDuplicates + $result.PublisherDuplicates + $result.PathDuplicates
        $result.Success = $true
    }
    catch {
        $result.Error = "Failed to find duplicates: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    finally {
        $conn.Close()
        $conn.Dispose()
    }
    
    return $result
}

function Remove-DuplicateRulesFromDatabase {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [ValidateSet('Hash', 'Publisher', 'Path', 'All')]
        [string]$RuleType = 'All',
        
        [ValidateSet('KeepOldest', 'KeepNewest', 'KeepApproved')]
        [string]$Strategy = 'KeepOldest'
    )
    
    $result = [PSCustomObject]@{
        Success      = $false
        RemovedCount = 0
        Error        = $null
    }
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) {
        $result.Error = "Database not found"
        return $result
    }
    
    # Get duplicates first
    $dupes = Get-DuplicateRules -RuleType $RuleType
    if (-not $dupes.Success) {
        $result.Error = $dupes.Error
        return $result
    }
    
    if ($dupes.TotalDuplicates -eq 0) {
        $result.Success = $true
        return $result
    }
    
    if ($WhatIfPreference) {
        Write-Host "WhatIf: Would remove $($dupes.TotalDuplicates) duplicate rules" -ForegroundColor Cyan
        $result.Success = $true
        $result.RemovedCount = $dupes.TotalDuplicates
        return $result
    }
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        $orderBy = switch ($Strategy) {
            'KeepOldest' { "CreatedDate ASC" }
            'KeepNewest' { "CreatedDate DESC" }
            'KeepApproved' { "CASE WHEN Status = 'Approved' THEN 0 ELSE 1 END, CreatedDate ASC" }
        }
        
        foreach ($group in $dupes.DuplicateGroups) {
            # Get IDs sorted by strategy, skip first (the one to keep)
            $idsToRemove = $group.RuleIds | Select-Object -Skip 1
            
            foreach ($id in $idsToRemove) {
                $sql = "DELETE FROM Rules WHERE Id = @Id;"
                $affected = Invoke-SqliteNonQuery -Connection $conn -CommandText $sql -Parameters @{ Id = $id }
                if ($affected -gt 0) { $result.RemovedCount++ }
            }
        }
        
        $result.Success = $true
        Write-StorageLog -Message "Removed $($result.RemovedCount) duplicate rules"
    }
    catch {
        $result.Error = "Failed to remove duplicates: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    finally {
        $conn.Close()
        $conn.Dispose()
    }
    
    return $result
}
