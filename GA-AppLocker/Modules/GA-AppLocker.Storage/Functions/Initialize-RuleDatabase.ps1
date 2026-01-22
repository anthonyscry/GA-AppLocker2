<#
.SYNOPSIS
    Initializes the SQLite database for rule storage.

.DESCRIPTION
    Creates the Rules.db database with proper schema and indexes.
    Safe to call multiple times - will not overwrite existing data.
#>

function Get-RuleDatabasePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    $dataPath = if (Get-Command -Name 'Get-AppLockerDataPath' -ErrorAction SilentlyContinue) {
        Get-AppLockerDataPath
    } else {
        Join-Path $env:LOCALAPPDATA 'GA-AppLocker'
    }
    
    return Join-Path $dataPath 'Rules.db'
}

function Test-RuleDatabaseExists {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $dbPath = Get-RuleDatabasePath
    return (Test-Path $dbPath)
}

function script:Get-SqliteConnection {
    [CmdletBinding()]
    param([string]$DatabasePath)
    
    if (-not $script:SqliteAssemblyLoaded) {
        if (-not (Initialize-SqliteAssembly)) {
            throw "SQLite assembly not available"
        }
    }
    
    if ($script:UseMicrosoftSqlite) {
        $conn = New-Object Microsoft.Data.Sqlite.SqliteConnection "Data Source=$DatabasePath"
    } else {
        $conn = New-Object System.Data.SQLite.SQLiteConnection "Data Source=$DatabasePath;Version=3;"
    }
    
    return $conn
}

function script:Invoke-SqliteNonQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$CommandText,
        [hashtable]$Parameters = @{}
    )
    
    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = $CommandText
    
    foreach ($key in $Parameters.Keys) {
        $param = $cmd.CreateParameter()
        $param.ParameterName = "@$key"
        $param.Value = if ($null -eq $Parameters[$key]) { [DBNull]::Value } else { $Parameters[$key] }
        [void]$cmd.Parameters.Add($param)
    }
    
    return $cmd.ExecuteNonQuery()
}

function script:Invoke-SqliteQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$CommandText,
        [hashtable]$Parameters = @{}
    )
    
    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = $CommandText
    
    foreach ($key in $Parameters.Keys) {
        $param = $cmd.CreateParameter()
        $param.ParameterName = "@$key"
        $param.Value = if ($null -eq $Parameters[$key]) { [DBNull]::Value } else { $Parameters[$key] }
        [void]$cmd.Parameters.Add($param)
    }
    
    $reader = $cmd.ExecuteReader()
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    while ($reader.Read()) {
        $row = [ordered]@{}
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
            $value = $reader.GetValue($i)
            $row[$reader.GetName($i)] = if ($value -is [DBNull]) { $null } else { $value }
        }
        $results.Add([PSCustomObject]$row)
    }
    
    $reader.Close()
    return $results
}

function script:Invoke-SqliteScalar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][string]$CommandText,
        [hashtable]$Parameters = @{}
    )
    
    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = $CommandText
    
    foreach ($key in $Parameters.Keys) {
        $param = $cmd.CreateParameter()
        $param.ParameterName = "@$key"
        $param.Value = if ($null -eq $Parameters[$key]) { [DBNull]::Value } else { $Parameters[$key] }
        [void]$cmd.Parameters.Add($param)
    }
    
    $result = $cmd.ExecuteScalar()
    return if ($result -is [DBNull]) { $null } else { $result }
}

function Initialize-RuleDatabase {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [switch]$Force
    )
    
    $result = [PSCustomObject]@{
        Success = $false
        DatabasePath = $null
        Created = $false
        Error = $null
    }
    
    try {
        $dbPath = Get-RuleDatabasePath
        $result.DatabasePath = $dbPath
        
        # Ensure directory exists
        $dbDir = Split-Path -Parent $dbPath
        if (-not (Test-Path $dbDir)) {
            New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
        }
        
        # Check if database already exists
        $dbExists = Test-Path $dbPath
        if ($dbExists -and -not $Force) {
            $result.Success = $true
            $result.Created = $false
            Write-StorageLog -Message "Database already exists at: $dbPath"
            return $result
        }
        
        if ($Force -and $dbExists) {
            Remove-Item -Path $dbPath -Force
            Write-StorageLog -Message "Removed existing database (Force mode)"
        }
        
        # Create database and schema
        $conn = Get-SqliteConnection -DatabasePath $dbPath
        $conn.Open()
        
        try {
            # Create Rules table
            $createTableSql = @"
CREATE TABLE IF NOT EXISTS Rules (
    Id TEXT PRIMARY KEY,
    RuleType TEXT NOT NULL,
    CollectionType TEXT NOT NULL,
    Status TEXT NOT NULL DEFAULT 'Pending',
    Name TEXT,
    Description TEXT,
    
    -- Hash rule fields
    Hash TEXT,
    HashType TEXT,
    
    -- Publisher rule fields  
    PublisherName TEXT,
    ProductName TEXT,
    BinaryName TEXT,
    MinVersion TEXT,
    MaxVersion TEXT,
    
    -- Path rule fields
    Path TEXT,
    
    -- Metadata
    SourceFile TEXT,
    SourceMachine TEXT,
    GroupName TEXT,
    GroupVendor TEXT,
    
    -- Timestamps
    CreatedDate TEXT NOT NULL,
    ModifiedDate TEXT,
    
    -- Full JSON payload for extensibility
    PayloadJson TEXT
);
"@
            Invoke-SqliteNonQuery -Connection $conn -CommandText $createTableSql | Out-Null
            
            # Create indexes for fast lookups
            $indexes = @(
                "CREATE INDEX IF NOT EXISTS idx_rules_status ON Rules(Status);",
                "CREATE INDEX IF NOT EXISTS idx_rules_ruletype ON Rules(RuleType);",
                "CREATE INDEX IF NOT EXISTS idx_rules_collectiontype ON Rules(CollectionType);",
                "CREATE INDEX IF NOT EXISTS idx_rules_hash ON Rules(Hash);",
                "CREATE INDEX IF NOT EXISTS idx_rules_publisher ON Rules(PublisherName, ProductName);",
                "CREATE INDEX IF NOT EXISTS idx_rules_path ON Rules(Path);",
                "CREATE INDEX IF NOT EXISTS idx_rules_groupvendor ON Rules(GroupVendor);",
                "CREATE INDEX IF NOT EXISTS idx_rules_created ON Rules(CreatedDate);"
            )
            
            foreach ($indexSql in $indexes) {
                Invoke-SqliteNonQuery -Connection $conn -CommandText $indexSql | Out-Null
            }
            
            # Create metadata table for tracking
            $metadataSql = @"
CREATE TABLE IF NOT EXISTS Metadata (
    Key TEXT PRIMARY KEY,
    Value TEXT,
    UpdatedAt TEXT
);
"@
            Invoke-SqliteNonQuery -Connection $conn -CommandText $metadataSql | Out-Null
            
            # Set schema version
            $versionSql = "INSERT OR REPLACE INTO Metadata (Key, Value, UpdatedAt) VALUES ('SchemaVersion', '1.0', @now);"
            Invoke-SqliteNonQuery -Connection $conn -CommandText $versionSql -Parameters @{ now = (Get-Date -Format 'o') } | Out-Null
            
            $result.Success = $true
            $result.Created = $true
            Write-StorageLog -Message "Created new database at: $dbPath"
        }
        finally {
            $conn.Close()
            $conn.Dispose()
        }
    }
    catch {
        $result.Error = "Failed to initialize database: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    
    return $result
}
