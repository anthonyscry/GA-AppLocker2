#Requires -Version 5.1
<#
.SYNOPSIS
    JSON-based storage layer for GA-AppLocker rules.

.DESCRIPTION
    Provides high-performance indexed storage for AppLocker rules using JSON files.
    Uses a central index file with in-memory hashtables for O(1) lookups.

.NOTES
    Version 2.0.0 - Simplified to JSON-only storage (removed SQLite dependency)
#>

#region ===== SAFE LOGGING =====
# Changed from script: to regular function so dot-sourced files can call it
function Write-StorageLog {
    param([string]$Message, [string]$Level = 'INFO')
    if (Get-Command -Name 'Write-AppLockerLog' -ErrorAction SilentlyContinue) {
        Write-AppLockerLog -Message "[Storage] $Message" -Level $Level
    } else {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Write-Verbose "[$timestamp] [$Level] [Storage] $Message"
    }
}
#endregion

#region ===== DOT-SOURCE FUNCTIONS =====
Get-RuleStoragePath = Join-Path $PSScriptRoot 'Functions\Get-RuleStoragePath.ps1'
if (Test-Path $Get-RuleStoragePath) {
    . $Get-RuleStoragePath
}
#endregion

Write-StorageLog -Message "Storage module loaded (JSON-only mode)"

Export-ModuleMember -Function @(
    # Rule Storage Operations (JSON-based)
    'Get-RuleStoragePath',
    'Get-RuleById',
    'Get-AllRules',
    'Add-Rule',
    'Update-Rule',
    'Remove-Rule',
    'Find-RuleByHash',
    'Find-RuleByPublisher',
    
    # Bulk Operations (Batch Rule Generation)
    'Get-RuleCounts',
    'Save-RulesBulk',
    'Add-RulesToIndex',
    'Get-ExistingRuleIndex',
    'Remove-RulesBulk',
    'Remove-RulesFromIndex',
    'Get-BatchPreview',
    'Update-RuleStatusInIndex',
    
    # Index Management
    '"Initialize-RuleIndexFromRules"'
    'Initialize-RuleIndexFromRules',
    'Reset-RulesIndexCache',
    'Rebuild-RulesIndex',
    'Remove-OrphanedRuleFiles',
    
    # Index Watcher Functions
    'Start-RuleIndexWatcher',
    'Stop-RuleIndexWatcher',
    'Get-RuleIndexWatcherStatus',
    'Set-RuleIndexWatcherDebounce',
    'Invoke-RuleIndexRebuild',
    
    # Repository Pattern Functions
    'Get-RuleFromRepository',
    'Save-RuleToRepository',
    'Remove-RuleFromRepository',
    'Find-RulesInRepository',
    'Get-RuleCountsFromRepository',
    'Invoke-RuleBatchOperation',
    'Test-RuleExistsInRepository',
    
    # Backwards Compatibility Aliases (needed by Rules module)
    'Get-RulesFromDatabase',
    'Get-RuleFromDatabase',
    'Add-RuleToDatabase',
    'Update-RuleInDatabase',
    'Remove-RuleFromDatabase',
    'Initialize-RuleDatabase',
    'Get-RuleDatabasePath',
    'Test-RuleDatabaseExists'
)
    'Initialize-RuleIndexFromRules',

    # Backwards Compatibility Aliases (needed by Rules module)
    'Get-RulesFromDatabase',
    'Get-RuleFromDatabase',
    'Add-RuleToDatabase',
    'Update-RuleInDatabase',
    'Remove-RuleFromDatabase',
    'Initialize-RuleDatabase',
    'Get-RuleDatabasePath',
    'Test-RuleDatabaseExists'
)
