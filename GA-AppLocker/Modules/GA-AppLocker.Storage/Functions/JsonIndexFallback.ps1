<#
.SYNOPSIS
    JSON Index fallback when SQLite is not available.

.DESCRIPTION
    Uses a single rules-index.json file with in-memory hashtables for O(1) lookups.
    This provides SQLite-like performance without external dependencies.
#>

$script:JsonIndexPath = $null
$script:JsonIndex = $null
$script:JsonIndexLoaded = $false
$script:HashIndex = @{}
$script:PublisherIndex = @{}
$script:RuleById = @{}

function script:Get-JsonIndexPath {
    if (-not $script:JsonIndexPath) {
        $dataPath = if (Get-Command -Name 'Get-AppLockerDataPath' -ErrorAction SilentlyContinue) {
            Get-AppLockerDataPath
        } else {
            Join-Path $env:LOCALAPPDATA 'GA-AppLocker'
        }
        $script:JsonIndexPath = Join-Path $dataPath 'rules-index.json'
    }
    return $script:JsonIndexPath
}

function script:Initialize-JsonIndex {
    [CmdletBinding()]
    param([switch]$Force)
    
    if ($script:JsonIndexLoaded -and -not $Force) { return }
    
    $indexPath = Get-JsonIndexPath
    
    if (Test-Path $indexPath) {
        try {
            $content = [System.IO.File]::ReadAllText($indexPath)
            $script:JsonIndex = $content | ConvertFrom-Json
            
            # Convert to hashtables for O(1) lookup
            $script:HashIndex = @{}
            $script:PublisherIndex = @{}
            $script:RuleById = @{}
            
            foreach ($rule in $script:JsonIndex.Rules) {
                $script:RuleById[$rule.Id] = $rule
                
                if ($rule.Hash) {
                    $script:HashIndex[$rule.Hash.ToUpper()] = $rule.Id
                }
                if ($rule.PublisherName) {
                    $key = "$($rule.PublisherName)|$($rule.ProductName)".ToLower()
                    $script:PublisherIndex[$key] = $rule.Id
                }
            }
            
            $script:JsonIndexLoaded = $true
            Write-StorageLog -Message "Loaded JSON index with $($script:JsonIndex.Rules.Count) rules"
        }
        catch {
            Write-StorageLog -Message "Failed to load JSON index: $($_.Exception.Message)" -Level 'ERROR'
            $script:JsonIndex = [PSCustomObject]@{ Rules = @(); LastUpdated = (Get-Date -Format 'o') }
        }
    }
    else {
        $script:JsonIndex = [PSCustomObject]@{ Rules = @(); LastUpdated = (Get-Date -Format 'o') }
        $script:HashIndex = @{}
        $script:PublisherIndex = @{}
        $script:RuleById = @{}
        $script:JsonIndexLoaded = $true
    }
}

function script:Save-JsonIndex {
    [CmdletBinding()]
    param()
    
    $indexPath = Get-JsonIndexPath
    $dir = Split-Path -Parent $indexPath
    
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
    
    $script:JsonIndex.LastUpdated = Get-Date -Format 'o'
    $script:JsonIndex | ConvertTo-Json -Depth 10 -Compress | Set-Content -Path $indexPath -Encoding UTF8
}

function script:Build-JsonIndexFromFiles {
    [CmdletBinding()]
    param(
        [string]$RulesPath,
        [scriptblock]$ProgressCallback
    )
    
    $result = [PSCustomObject]@{
        Success = $false
        RuleCount = 0
        Duration = $null
        Error = $null
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    if (-not $RulesPath) {
        $dataPath = if (Get-Command -Name 'Get-AppLockerDataPath' -ErrorAction SilentlyContinue) {
            Get-AppLockerDataPath
        } else {
            Join-Path $env:LOCALAPPDATA 'GA-AppLocker'
        }
        $RulesPath = Join-Path $dataPath 'Rules'
    }
    
    if (-not (Test-Path $RulesPath)) {
        $result.Success = $true
        $result.Error = "No rules directory at: $RulesPath"
        return $result
    }
    
    try {
        $rules = [System.Collections.Generic.List[PSCustomObject]]::new()
        $files = [System.IO.Directory]::EnumerateFiles($RulesPath, '*.json', [System.IO.SearchOption]::TopDirectoryOnly)
        $fileList = [System.Collections.Generic.List[string]]::new()
        foreach ($f in $files) { $fileList.Add($f) }
        
        $totalFiles = $fileList.Count
        $processed = 0
        
        Write-StorageLog -Message "Building index from $totalFiles JSON files..."
        
        foreach ($filePath in $fileList) {
            $processed++
            
            try {
                $content = [System.IO.File]::ReadAllText($filePath)
                $rule = $content | ConvertFrom-Json
                
                if ($rule.Id) {
                    $indexEntry = [PSCustomObject]@{
                        Id = $rule.Id
                        RuleType = $rule.RuleType
                        CollectionType = $rule.CollectionType
                        Status = if ($rule.Status) { $rule.Status } else { 'Pending' }
                        Name = $rule.Name
                        Hash = $rule.Hash
                        PublisherName = $rule.PublisherName
                        ProductName = $rule.ProductName
                        Path = $rule.Path
                        GroupVendor = $rule.GroupVendor
                        CreatedDate = $rule.CreatedDate
                        FilePath = $filePath
                    }
                    $rules.Add($indexEntry)
                }
            }
            catch { }
            
            if ($ProgressCallback -and ($processed % 1000 -eq 0)) {
                $pct = [math]::Round(($processed / $totalFiles) * 100)
                & $ProgressCallback $processed $totalFiles $pct
            }
        }
        
        $script:JsonIndex = [PSCustomObject]@{
            Rules = $rules.ToArray()
            LastUpdated = Get-Date -Format 'o'
            SourcePath = $RulesPath
        }
        
        # Rebuild hashtables
        $script:HashIndex = @{}
        $script:PublisherIndex = @{}
        $script:RuleById = @{}
        
        foreach ($rule in $rules) {
            $script:RuleById[$rule.Id] = $rule
            if ($rule.Hash) {
                $script:HashIndex[$rule.Hash.ToUpper()] = $rule.Id
            }
            if ($rule.PublisherName) {
                $key = "$($rule.PublisherName)|$($rule.ProductName)".ToLower()
                $script:PublisherIndex[$key] = $rule.Id
            }
        }
        
        Save-JsonIndex
        $script:JsonIndexLoaded = $true
        
        $stopwatch.Stop()
        $result.Success = $true
        $result.RuleCount = $rules.Count
        $result.Duration = $stopwatch.Elapsed
        
        Write-StorageLog -Message "Built JSON index: $($rules.Count) rules in $($stopwatch.Elapsed.TotalSeconds.ToString('F1'))s"
    }
    catch {
        $result.Error = "Failed to build index: $($_.Exception.Message)"
        Write-StorageLog -Message $result.Error -Level 'ERROR'
    }
    
    return $result
}

# Only define fallback functions if SQLite is not available
if (-not $script:SqliteAssemblyLoaded) {
    
    Write-StorageLog -Message "Initializing JSON index fallback mode"
    
    # Redefine Initialize-RuleDatabase for JSON mode
    function Initialize-RuleDatabase {
        [CmdletBinding()]
        param([switch]$Force)
        
        $result = [PSCustomObject]@{
            Success = $false
            DatabasePath = Get-JsonIndexPath
            Created = $false
            Mode = 'JsonIndex'
            Error = $null
        }
        
        try {
            if ($Force) {
                $script:JsonIndexLoaded = $false
                $script:JsonIndex = $null
            }
            
            Initialize-JsonIndex -Force:$Force
            
            # If no index and JSON rules exist, build it
            $rules = $script:JsonIndex.Rules
            if (-not $rules -or $rules.Count -eq 0) {
                $dataPath = if (Get-Command -Name 'Get-AppLockerDataPath' -ErrorAction SilentlyContinue) {
                    Get-AppLockerDataPath
                } else {
                    Join-Path $env:LOCALAPPDATA 'GA-AppLocker'
                }
                $rulesPath = Join-Path $dataPath 'Rules'
                
                if (Test-Path $rulesPath) {
                    $buildResult = Build-JsonIndexFromFiles -RulesPath $rulesPath
                    if ($buildResult.Success -and $buildResult.RuleCount -gt 0) {
                        $result.Created = $true
                    }
                }
            }
            
            $result.Success = $true
        }
        catch {
            $result.Error = "Failed to initialize JSON index: $($_.Exception.Message)"
        }
        
        return $result
    }
    
    # Redefine Get-RulesFromDatabase for JSON mode
    function Get-RulesFromDatabase {
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
            Data = @()
            Total = 0
            Error = $null
        }
        
        Initialize-JsonIndex
        
        $rules = $script:JsonIndex.Rules
        if (-not $rules) {
            $result.Success = $true
            return $result
        }
        
        try {
            $filtered = @($rules)
            
            if ($Status) {
                $filtered = @($filtered | Where-Object { $_.Status -eq $Status })
            }
            if ($RuleType) {
                $filtered = @($filtered | Where-Object { $_.RuleType -eq $RuleType })
            }
            if ($CollectionType) {
                $filtered = @($filtered | Where-Object { $_.CollectionType -eq $CollectionType })
            }
            if ($GroupVendor) {
                $filtered = @($filtered | Where-Object { $_.GroupVendor -like "*$GroupVendor*" })
            }
            if ($SearchText) {
                $filtered = @($filtered | Where-Object {
                    $_.Name -like "*$SearchText*" -or
                    $_.PublisherName -like "*$SearchText*" -or
                    $_.Path -like "*$SearchText*" -or
                    $_.Hash -like "*$SearchText*"
                })
            }
            
            $result.Total = $filtered.Count
            
            if (-not $CountOnly) {
                if ($FullPayload) {
                    $paged = $filtered | Select-Object -Skip $Skip -First $Take
                    $result.Data = @($paged | ForEach-Object {
                        if ($_.FilePath -and (Test-Path $_.FilePath)) {
                            Get-Content $_.FilePath -Raw | ConvertFrom-Json
                        } else { $_ }
                    })
                } else {
                    $result.Data = @($filtered | Select-Object -Skip $Skip -First $Take)
                }
            }
            
            $result.Success = $true
        }
        catch {
            $result.Error = "Query failed: $($_.Exception.Message)"
        }
        
        return $result
    }
    
    # Redefine Find-RuleByHash for JSON mode
    function Find-RuleByHash {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Hash,
            [string]$CollectionType
        )
        
        Initialize-JsonIndex
        
        $cleanHash = ($Hash -replace '^0x', '').ToUpper()
        
        if ($script:HashIndex.ContainsKey($cleanHash)) {
            $ruleId = $script:HashIndex[$cleanHash]
            $indexEntry = $script:RuleById[$ruleId]
            
            if ($CollectionType -and $indexEntry.CollectionType -ne $CollectionType) {
                return $null
            }
            
            if ($indexEntry.FilePath -and (Test-Path $indexEntry.FilePath)) {
                return Get-Content $indexEntry.FilePath -Raw | ConvertFrom-Json
            }
            return $indexEntry
        }
        
        return $null
    }
    
    # Redefine Find-RuleByPublisher for JSON mode
    function Find-RuleByPublisher {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$PublisherName,
            [string]$ProductName,
            [string]$CollectionType
        )
        
        Initialize-JsonIndex
        
        $key = "$PublisherName|$ProductName".ToLower()
        
        if ($script:PublisherIndex.ContainsKey($key)) {
            $ruleId = $script:PublisherIndex[$key]
            $indexEntry = $script:RuleById[$ruleId]
            
            if ($CollectionType -and $indexEntry.CollectionType -ne $CollectionType) {
                return $null
            }
            
            if ($indexEntry.FilePath -and (Test-Path $indexEntry.FilePath)) {
                return Get-Content $indexEntry.FilePath -Raw | ConvertFrom-Json
            }
            return $indexEntry
        }
        
        return $null
    }
    
    # Redefine Get-RuleCounts for JSON mode
    function Get-RuleCounts {
        [CmdletBinding()]
        param()
        
        $result = [PSCustomObject]@{
            Success = $false
            Total = 0
            ByStatus = @{}
            ByRuleType = @{}
            ByCollection = @{}
            Error = $null
        }
        
        Initialize-JsonIndex
        
        $rules = $script:JsonIndex.Rules
        if (-not $rules) {
            $result.Success = $true
            return $result
        }
        
        try {
            $result.Total = $rules.Count
            
            $rules | Group-Object Status | ForEach-Object {
                if ($_.Name) { $result.ByStatus[$_.Name] = $_.Count }
            }
            
            $rules | Group-Object RuleType | ForEach-Object {
                if ($_.Name) { $result.ByRuleType[$_.Name] = $_.Count }
            }
            
            $rules | Group-Object CollectionType | ForEach-Object {
                if ($_.Name) { $result.ByCollection[$_.Name] = $_.Count }
            }
            
            $result.Success = $true
        }
        catch {
            $result.Error = "Failed to get counts: $($_.Exception.Message)"
        }
        
        return $result
    }
    
    # Redefine Import-RulesToDatabase for JSON mode  
    function Import-RulesToDatabase {
        [CmdletBinding()]
        param(
            [string]$JsonRulesPath,
            [int]$BatchSize = 500,
            [switch]$Force,
            [scriptblock]$ProgressCallback
        )
        
        return Build-JsonIndexFromFiles -RulesPath $JsonRulesPath -ProgressCallback $ProgressCallback
    }
}
