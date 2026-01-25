<#
.SYNOPSIS
    CRUD operations for rules in SQLite database.
#>

function Get-RulesFromJsonIndex {
    <#
    .SYNOPSIS
        Gets rules from JSON index when SQLite is unavailable.
    #>
    [CmdletBinding()]
    param(
        [string]$Status,
        [string]$RuleType,
        [string]$CollectionType,
        [string]$SearchText,
        [string]$GroupVendor,
        [int]$Skip = 0,
        [int]$Take = 1000,
        [switch]$CountOnly,
        [switch]$FullPayload
    )
    
    $result = [PSCustomObject]@{
        Success = $false
        Data    = @()
        Total   = 0
        Error   = $null
    }
    
    try {
        # Ensure JSON index is loaded
        Initialize-JsonIndex
        
        # Get rules from index
        $rules = @($script:JsonIndex.Rules)
        
        # Apply filters
        if ($Status) {
            $rules = @($rules | Where-Object { $_.Status -eq $Status })
        }
        if ($RuleType) {
            $rules = @($rules | Where-Object { $_.RuleType -eq $RuleType })
        }
        if ($CollectionType) {
            $rules = @($rules | Where-Object { $_.CollectionType -eq $CollectionType })
        }
        if ($GroupVendor) {
            $rules = @($rules | Where-Object { $_.GroupVendor -like "*$GroupVendor*" })
        }
        if ($SearchText) {
            $searchLower = $SearchText.ToLower()
            $rules = @($rules | Where-Object {
                ($_.Name -and $_.Name.ToLower().Contains($searchLower)) -or
                ($_.PublisherName -and $_.PublisherName.ToLower().Contains($searchLower)) -or
                ($_.Path -and $_.Path.ToLower().Contains($searchLower)) -or
                ($_.Hash -and $_.Hash.ToLower().Contains($searchLower))
            })
        }
        
        $result.Total = $rules.Count
        
        if ($CountOnly) {
            $result.Success = $true
            return $result
        }
        
        # Apply pagination
        if ($Skip -gt 0) {
            $rules = @($rules | Select-Object -Skip $Skip)
        }
        if ($Take -gt 0) {
            $rules = @($rules | Select-Object -First $Take)
        }
        
        # If full payload requested, load full rule from JSON files
        if ($FullPayload) {
            $dataPath = if (Get-Command -Name 'Get-AppLockerDataPath' -ErrorAction SilentlyContinue) {
                Get-AppLockerDataPath
            } else {
                Join-Path $env:LOCALAPPDATA 'GA-AppLocker'
            }
            $rulesPath = Join-Path $dataPath 'Rules'
            
            $fullRules = [System.Collections.Generic.List[PSCustomObject]]::new()
            foreach ($indexEntry in $rules) {
                $rulePath = Join-Path $rulesPath "$($indexEntry.Id).json"
                if (Test-Path $rulePath) {
                    try {
                        $content = [System.IO.File]::ReadAllText($rulePath)
                        $fullRule = $content | ConvertFrom-Json
                        $fullRules.Add($fullRule)
                    }
                    catch {
                        # If can't load full rule, use index entry
                        $fullRules.Add($indexEntry)
                    }
                }
                else {
                    $fullRules.Add($indexEntry)
                }
            }
            $result.Data = @($fullRules)
        }
        else {
            $result.Data = @($rules)
        }
        
        $result.Success = $true
    }
    catch {
        $result.Error = "JSON index query failed: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    
    return $result
}

function Add-RuleToDatabase {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]$Rule
    )
    
    begin {
        $dbPath = Get-RuleDatabasePath
        if (-not (Test-Path $dbPath)) {
            Initialize-RuleDatabase | Out-Null
        }
        $conn = Get-SqliteConnection -DatabasePath $dbPath
        $conn.Open()
        $addedCount = 0
    }
    
    process {
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
            $params = @{
                Id             = $Rule.Id
                RuleType       = $Rule.RuleType
                CollectionType = $Rule.CollectionType
                Status         = if ($Rule.Status) { $Rule.Status } else { 'Pending' }
                Name           = $Rule.Name
                Description    = $Rule.Description
                Hash           = $Rule.Hash
                HashType       = $Rule.HashType
                PublisherName  = $Rule.PublisherName
                ProductName    = $Rule.ProductName
                BinaryName     = $Rule.BinaryName
                MinVersion     = $Rule.MinVersion
                MaxVersion     = $Rule.MaxVersion
                Path           = $Rule.Path
                SourceFile     = $Rule.SourceFile
                SourceMachine  = $Rule.SourceMachine
                GroupName      = $Rule.GroupName
                GroupVendor    = $Rule.GroupVendor
                CreatedDate    = if ($Rule.CreatedDate) { $Rule.CreatedDate } else { (Get-Date -Format 'o') }
                ModifiedDate   = Get-Date -Format 'o'
                PayloadJson    = ($Rule | ConvertTo-Json -Depth 10 -Compress)
            }
            
            Invoke-SqliteNonQuery -Connection $conn -CommandText $sql -Parameters $params | Out-Null
            $addedCount++
        }
        catch {
            Write-StorageLog -Message "Failed to add rule $($Rule.Id): $($_.Exception.Message)" -Level 'ERROR'
        }
    }
    
    end {
        $conn.Close()
        $conn.Dispose()
        
        return [PSCustomObject]@{
            Success = $true
            AddedCount = $addedCount
        }
    }
}

function Get-RuleFromDatabase {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) {
        return $null
    }
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        $sql = "SELECT PayloadJson FROM Rules WHERE Id = @Id;"
        $result = Invoke-SqliteScalar -Connection $conn -CommandText $sql -Parameters @{ Id = $Id }
        
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

function Get-RulesFromDatabase {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$Status,
        [string]$RuleType,
        [string]$CollectionType,
        [string]$SearchText,
        [string]$GroupVendor,
        [int]$Skip = 0,
        [int]$Take = 1000,
        [switch]$CountOnly,
        [switch]$FullPayload
    )
    
    $result = [PSCustomObject]@{
        Success = $false
        Data    = @()
        Total   = 0
        Error   = $null
    }
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) {
        # SQLite DB doesn't exist - fall back to JSON index
        return Get-RulesFromJsonIndex -Status $Status -RuleType $RuleType -CollectionType $CollectionType `
            -SearchText $SearchText -GroupVendor $GroupVendor -Skip $Skip -Take $Take `
            -CountOnly:$CountOnly -FullPayload:$FullPayload
    }
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        # Build WHERE clause
        $conditions = [System.Collections.Generic.List[string]]::new()
        $params = @{}
        
        if ($Status) {
            $conditions.Add("Status = @Status")
            $params.Status = $Status
        }
        if ($RuleType) {
            $conditions.Add("RuleType = @RuleType")
            $params.RuleType = $RuleType
        }
        if ($CollectionType) {
            $conditions.Add("CollectionType = @CollectionType")
            $params.CollectionType = $CollectionType
        }
        if ($GroupVendor) {
            $conditions.Add("GroupVendor LIKE @GroupVendor")
            $params.GroupVendor = "%$GroupVendor%"
        }
        if ($SearchText) {
            $conditions.Add("(Name LIKE @Search OR PublisherName LIKE @Search OR Path LIKE @Search OR Hash LIKE @Search)")
            $params.Search = "%$SearchText%"
        }
        
        $whereClause = if ($conditions.Count -gt 0) { "WHERE " + ($conditions -join " AND ") } else { "" }
        
        # Get total count
        $countSql = "SELECT COUNT(*) FROM Rules $whereClause;"
        $result.Total = [int](Invoke-SqliteScalar -Connection $conn -CommandText $countSql -Parameters $params)
        
        if ($CountOnly) {
            $result.Success = $true
            return $result
        }
        
        # Get data
        $columns = if ($FullPayload) {
            "PayloadJson"
        } else {
            "Id, RuleType, CollectionType, Status, Name, Hash, PublisherName, ProductName, Path, GroupVendor, CreatedDate"
        }
        
        $dataSql = "SELECT $columns FROM Rules $whereClause ORDER BY CreatedDate DESC LIMIT @Take OFFSET @Skip;"
        $params.Take = $Take
        $params.Skip = $Skip
        
        $rows = Invoke-SqliteQuery -Connection $conn -CommandText $dataSql -Parameters $params
        
        if ($FullPayload) {
            $result.Data = @($rows | ForEach-Object { $_.PayloadJson | ConvertFrom-Json })
        } else {
            $result.Data = @($rows)
        }
        
        $result.Success = $true
    }
    catch {
        $result.Error = "Query failed: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    finally {
        $conn.Close()
        $conn.Dispose()
    }
    
    return $result
}

function Update-RuleInDatabase {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Id,
        
        [string]$Status,
        [string]$Name,
        [string]$Description,
        [string]$GroupName,
        [string]$GroupVendor
    )
    
    $result = [PSCustomObject]@{
        Success = $false
        Error   = $null
    }
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) {
        $result.Error = "Database not found"
        return $result
    }
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        $updates = [System.Collections.Generic.List[string]]::new()
        $params = @{ Id = $Id; ModifiedDate = (Get-Date -Format 'o') }
        
        if ($PSBoundParameters.ContainsKey('Status')) {
            $updates.Add("Status = @Status")
            $params.Status = $Status
        }
        if ($PSBoundParameters.ContainsKey('Name')) {
            $updates.Add("Name = @Name")
            $params.Name = $Name
        }
        if ($PSBoundParameters.ContainsKey('Description')) {
            $updates.Add("Description = @Description")
            $params.Description = $Description
        }
        if ($PSBoundParameters.ContainsKey('GroupName')) {
            $updates.Add("GroupName = @GroupName")
            $params.GroupName = $GroupName
        }
        if ($PSBoundParameters.ContainsKey('GroupVendor')) {
            $updates.Add("GroupVendor = @GroupVendor")
            $params.GroupVendor = $GroupVendor
        }
        
        $updates.Add("ModifiedDate = @ModifiedDate")
        
        $sql = "UPDATE Rules SET " + ($updates -join ", ") + " WHERE Id = @Id;"
        $affected = Invoke-SqliteNonQuery -Connection $conn -CommandText $sql -Parameters $params
        
        $result.Success = $affected -gt 0
        if (-not $result.Success) {
            $result.Error = "Rule not found: $Id"
        }
    }
    catch {
        $result.Error = "Update failed: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    finally {
        $conn.Close()
        $conn.Dispose()
    }
    
    return $result
}

function Remove-RuleFromDatabase {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string[]]$Id
    )
    
    $result = [PSCustomObject]@{
        Success = $false
        RemovedCount = 0
        Error = $null
    }
    
    $dbPath = Get-RuleDatabasePath
    if (-not (Test-Path $dbPath)) {
        $result.Error = "Database not found"
        return $result
    }
    
    $conn = Get-SqliteConnection -DatabasePath $dbPath
    $conn.Open()
    
    try {
        foreach ($ruleId in $Id) {
            $sql = "DELETE FROM Rules WHERE Id = @Id;"
            $affected = Invoke-SqliteNonQuery -Connection $conn -CommandText $sql -Parameters @{ Id = $ruleId }
            if ($affected -gt 0) { $result.RemovedCount++ }
        }
        $result.Success = $true
    }
    catch {
        $result.Error = "Delete failed: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    finally {
        $conn.Close()
        $conn.Dispose()
    }
    
    return $result
}
