@{
    RootModule = 'GA-AppLocker.Storage.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a8b7c6d5-e4f3-4a2b-9c1d-0e8f7a6b5c4d'
    Author = 'GA-AppLocker Team'
    Description = 'SQLite storage layer for GA-AppLocker rules and data'
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @(
        # Database Management
        'Initialize-RuleDatabase',
        'Get-RuleDatabasePath',
        'Test-RuleDatabaseExists',
        
        # Rule CRUD Operations  
        'Add-RuleToDatabase',
        'Get-RuleFromDatabase',
        'Get-RulesFromDatabase',
        'Update-RuleInDatabase',
        'Remove-RuleFromDatabase',
        
        # Bulk Operations (Batch Rule Generation)
        'Import-RulesToDatabase',
        'Get-RuleCounts',
        'Save-RulesBulk',
        'Add-RulesToIndex',
        'Get-ExistingRuleIndex',
        'Remove-RulesBulk',
        'Remove-RulesFromIndex',
        'Get-BatchPreview',
        'Update-RuleStatusInIndex',
        
        # Query Helpers
        'Find-RuleByHash',
        'Find-RuleByPublisher',
        'Get-DuplicateRules',
        
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
        
        # Cache Management
        'Clear-RulesIndex',
        'Reset-RulesIndexCache'
    )
    
    PrivateData = @{
        PSData = @{
            Tags = @('AppLocker', 'SQLite', 'Storage')
        }
    }
}
