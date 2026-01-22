<#
.SYNOPSIS
    Imports existing JSON rule files into SQLite database.

.DESCRIPTION
    One-time migration from JSON files to SQLite. Uses batched transactions
    for performance (~500 rules per transaction).
#>

function Import-RulesToDatabase {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$JsonRulesPath,
        [int]$BatchSize = 500,
        [switch]$Force,
        [scriptblock]$ProgressCallback
    )
    
    $result = [PSCustomObject]@{
        Success       = $false
        ImportedCount = 0
        SkippedCount  = 0
        ErrorCount    = 0
        TotalFiles    = 0
        Duration      = $null
        Error         = $null
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Determine JSON rules path
        if (-not $JsonRulesPath) {
            $dataPath = if (Get-Command -Name 'Get-AppLockerDataPath' -ErrorAction SilentlyContinue) {
                Get-AppLockerDataPath
            } else {
                Join-Path $env:LOCALAPPDATA 'GA-AppLocker'
            }
            $JsonRulesPath = Join-Path $dataPath 'Rules'
        }
        
        if (-not (Test-Path $JsonRulesPath)) {
            $result.Success = $true
            $result.Error = "No JSON rules directory found at: $JsonRulesPath"
            Write-StorageLog -Message $result.Error -Level 'INFO'
            return $result
        }
        
        # Initialize database if needed
        $initResult = Initialize-RuleDatabase -Force:$Force
        if (-not $initResult.Success) {
            $result.Error = "Failed to initialize database: $($initResult.Error)"
            return $result
        }
        
        # Use fast enumeration instead of Get-ChildItem
        $jsonFiles = [System.IO.Directory]::EnumerateFiles($JsonRulesPath, '*.json', [System.IO.SearchOption]::TopDirectoryOnly)
        $fileList = [System.Collections.Generic.List[string]]::new()
        foreach ($f in $jsonFiles) { $fileList.Add($f) }
        $result.TotalFiles = $fileList.Count
        
        if ($result.TotalFiles -eq 0) {
            $result.Success = $true
            Write-StorageLog -Message "No JSON rule files found"
            return $result
        }
        
        Write-StorageLog -Message "Starting import of $($result.TotalFiles) JSON rule files..."
        
        # Open connection for batch processing
        $dbPath = Get-RuleDatabasePath
        $conn = Get-SqliteConnection -DatabasePath $dbPath
        $conn.Open()
        
        try {
            $processedCount = 0
            $batchRules = [System.Collections.Generic.List[PSCustomObject]]::new()
            
            foreach ($filePath in $fileList) {
                $processedCount++
                
                try {
                    # Fast file read
                    $content = [System.IO.File]::ReadAllText($filePath)
                    $rule = $content | ConvertFrom-Json
                    
                    if (-not $rule.Id) {
                        $result.SkippedCount++
                        continue
                    }
                    
                    $batchRules.Add($rule)
                    
                    # Process batch
                    if ($batchRules.Count -ge $BatchSize) {
                        Import-RuleBatch -Connection $conn -Rules $batchRules
                        $result.ImportedCount += $batchRules.Count
                        $batchRules.Clear()
                        
                        # Progress callback
                        if ($ProgressCallback) {
                            $pct = [math]::Round(($processedCount / $result.TotalFiles) * 100)
                            & $ProgressCallback $processedCount $result.TotalFiles $pct
                        }
                    }
                }
                catch {
                    $result.ErrorCount++
                    Write-StorageLog -Message "Failed to parse $filePath : $($_.Exception.Message)" -Level 'DEBUG'
                }
            }
            
            # Process remaining batch
            if ($batchRules.Count -gt 0) {
                Import-RuleBatch -Connection $conn -Rules $batchRules
                $result.ImportedCount += $batchRules.Count
            }
            
            $result.Success = $true
            
        }
        finally {
            $conn.Close()
            $conn.Dispose()
        }
        
        $stopwatch.Stop()
        $result.Duration = $stopwatch.Elapsed
        
        Write-StorageLog -Message "Import complete: $($result.ImportedCount) rules in $($result.Duration.TotalSeconds.ToString('F1'))s"
    }
    catch {
        $result.Error = "Import failed: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    
    return $result
}

function script:Import-RuleBatch {
    param(
        [Parameter(Mandatory)]$Connection,
        [Parameter(Mandatory)][System.Collections.Generic.List[PSCustomObject]]$Rules
    )
    
    # Begin transaction for batch
    $transaction = $Connection.BeginTransaction()
    
    try {
        $sql = @"
INSERT OR REPLACE INTO Rules (
    Id, RuleType, CollectionType, Status, Name, Description,
    Hash, HashType, PublisherName, ProductName, BinaryName, MinVersion, MaxVersion,
    Path, SourceFile, SourceMachine, GroupName, GroupVendor,
    CreatedDate, ModifiedDate, PayloadJson
) VALUES (
    @Id, @RuleType, @CollectionType, @Status, @Name, @Description,
    @Hash, @HashType, @PublisherName, @ProductName, @BinaryName, @MinVersion, @MaxVersion,
    @Path, @SourceFile, @SourceMachine, @GroupName, @GroupVendor,
    @CreatedDate, @ModifiedDate, @PayloadJson
);
"@
        
        foreach ($rule in $Rules) {
            $params = @{
                Id             = $rule.Id
                RuleType       = $rule.RuleType
                CollectionType = $rule.CollectionType
                Status         = if ($rule.Status) { $rule.Status } else { 'Pending' }
                Name           = $rule.Name
                Description    = $rule.Description
                Hash           = $rule.Hash
                HashType       = $rule.HashType
                PublisherName  = $rule.PublisherName
                ProductName    = $rule.ProductName
                BinaryName     = $rule.BinaryName
                MinVersion     = $rule.MinVersion
                MaxVersion     = $rule.MaxVersion
                Path           = $rule.Path
                SourceFile     = $rule.SourceFile
                SourceMachine  = $rule.SourceMachine
                GroupName      = $rule.GroupName
                GroupVendor    = $rule.GroupVendor
                CreatedDate    = if ($rule.CreatedDate) { $rule.CreatedDate } else { (Get-Date -Format 'o') }
                ModifiedDate   = if ($rule.ModifiedDate) { $rule.ModifiedDate } else { (Get-Date -Format 'o') }
                PayloadJson    = ($rule | ConvertTo-Json -Depth 10 -Compress)
            }
            
            Invoke-SqliteNonQuery -Connection $Connection -CommandText $sql -Parameters $params | Out-Null
        }
        
        $transaction.Commit()
    }
    catch {
        $transaction.Rollback()
        throw
    }
}
