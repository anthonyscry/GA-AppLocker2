<#
.SYNOPSIS
    Event system for GA-AppLocker inter-component communication.

.DESCRIPTION
    Provides a publish/subscribe event system for loose coupling between
    components. Supports:
    - Named event registration with handlers
    - Event publishing with data payloads
    - Multiple handlers per event
    - Handler priority ordering
    - Event history for debugging

.NOTES
    Author: GA-AppLocker Team
    Version: 1.0.0
#>

#region ===== EVENT STORAGE =====
# Event handlers registry - using global scope with unique prefix to ensure
# state is shared across module boundaries when called from external scripts/tests
# This is necessary because nested modules create isolated script scopes

$global:GA_AppLocker_EventHistoryMaxSize = 100

# Standard event names
$script:StandardEvents = @(
    'RuleCreated',
    'RuleUpdated', 
    'RuleDeleted',
    'RuleBulkUpdated',
    'PolicyCreated',
    'PolicyUpdated',
    'PolicyDeleted',
    'ScanStarted',
    'ScanProgress',
    'ScanCompleted',
    'IndexRebuilt',
    'CacheCleared',
    'SessionRestored',
    'ErrorOccurred'
)

# Helper function to ensure storage is initialized (called at start of each public function)
function Initialize-EventStorage {
    if ($null -eq $global:GA_AppLocker_EventHandlers) {
        $global:GA_AppLocker_EventHandlers = [hashtable]::Synchronized(@{})
    }
    if ($null -eq $global:GA_AppLocker_EventHistory) {
        $global:GA_AppLocker_EventHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
}
#endregion

#region ===== PUBLIC FUNCTIONS =====

<#
.SYNOPSIS
    Registers an event handler.

.DESCRIPTION
    Subscribes a script block to be executed when a specific event is published.
    Multiple handlers can be registered for the same event.

.PARAMETER EventName
    Name of the event to subscribe to.

.PARAMETER Handler
    Script block to execute when event is published. Receives $EventData parameter.

.PARAMETER HandlerId
    Optional unique identifier for the handler. Auto-generated if not provided.

.PARAMETER Priority
    Handler priority (lower = earlier execution). Default is 100.

.EXAMPLE
    Register-AppLockerEvent -EventName 'RuleCreated' -Handler {
        param($EventData)
        Write-Host "Rule created: $($EventData.RuleId)"
        Clear-AppLockerCache -Pattern 'Rule*'
    }

.EXAMPLE
    Register-AppLockerEvent -EventName 'ScanCompleted' -Handler { Update-DashboardStats } -Priority 10

.OUTPUTS
    [string] The handler ID
#>
function Register-AppLockerEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EventName,

        [Parameter(Mandatory)]
        [scriptblock]$Handler,

        [Parameter()]
        [string]$HandlerId = [guid]::NewGuid().ToString(),

        [Parameter()]
        [int]$Priority = 100
    )

    Initialize-EventStorage
    
    if (-not $global:GA_AppLocker_EventHandlers.ContainsKey($EventName)) {
        $global:GA_AppLocker_EventHandlers[$EventName] = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    $handlerEntry = [PSCustomObject]@{
        Id = $HandlerId
        Handler = $Handler
        Priority = $Priority
        RegisteredAt = [DateTime]::UtcNow
    }

    $global:GA_AppLocker_EventHandlers[$EventName].Add($handlerEntry)
    
    # Sort by priority
    $sorted = $global:GA_AppLocker_EventHandlers[$EventName] | Sort-Object Priority
    $global:GA_AppLocker_EventHandlers[$EventName] = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($h in $sorted) {
        $global:GA_AppLocker_EventHandlers[$EventName].Add($h)
    }

    return $HandlerId
}

<#
.SYNOPSIS
    Publishes an event to all registered handlers.

.DESCRIPTION
    Triggers all handlers registered for the specified event, passing
    the event data to each handler.

.PARAMETER EventName
    Name of the event to publish.

.PARAMETER EventData
    Data to pass to event handlers. Can be any object.

.PARAMETER Async
    If specified, handlers are executed in background jobs (fire-and-forget).

.EXAMPLE
    Publish-AppLockerEvent -EventName 'RuleCreated' -EventData @{
        RuleId = 'rule-123'
        RuleType = 'Hash'
        CreatedBy = 'User'
    }

.EXAMPLE
    Publish-AppLockerEvent -EventName 'ScanProgress' -EventData @{ Percent = 50 } -Async

.OUTPUTS
    [PSCustomObject] Event result with handler execution status
#>
function Publish-AppLockerEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EventName,

        [Parameter()]
        $EventData = $null,

        [Parameter()]
        [switch]$Async
    )

    Initialize-EventStorage
    
    $eventRecord = [PSCustomObject]@{
        EventName = $EventName
        Timestamp = [DateTime]::UtcNow
        Data = $EventData
        HandlerCount = 0
        Errors = @()
    }

    # Add to history (circular buffer)
    $global:GA_AppLocker_EventHistory.Add($eventRecord)
    if ($global:GA_AppLocker_EventHistory.Count -gt $global:GA_AppLocker_EventHistoryMaxSize) {
        $global:GA_AppLocker_EventHistory.RemoveAt(0)
    }

    $handlers = $global:GA_AppLocker_EventHandlers[$EventName]
    if (-not $handlers -or $handlers.Count -eq 0) {
        return [PSCustomObject]@{
            Success = $true
            EventName = $EventName
            HandlersExecuted = 0
            Errors = @()
        }
    }

    $eventRecord.HandlerCount = $handlers.Count
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($handlerEntry in $handlers) {
        try {
            if ($Async) {
                # Fire and forget - don't wait for completion
                $null = Start-Job -ScriptBlock $handlerEntry.Handler -ArgumentList $EventData
            }
            else {
                # Synchronous execution
                & $handlerEntry.Handler $EventData
            }
        }
        catch {
            $errorMsg = "Handler $($handlerEntry.Id) failed: $($_.Exception.Message)"
            $errors.Add($errorMsg)
            
            # Log error but continue with other handlers
            if (Get-Command -Name 'Write-AppLockerLog' -ErrorAction SilentlyContinue) {
                Write-AppLockerLog -Level Warning -Message $errorMsg -NoConsole
            }
        }
    }

    $eventRecord.Errors = $errors.ToArray()

    return [PSCustomObject]@{
        Success = ($errors.Count -eq 0)
        EventName = $EventName
        HandlersExecuted = $handlers.Count
        Errors = $errors.ToArray()
    }
}

<#
.SYNOPSIS
    Unregisters an event handler.

.DESCRIPTION
    Removes a specific handler or all handlers for an event.

.PARAMETER EventName
    Name of the event.

.PARAMETER HandlerId
    ID of the specific handler to remove. If not specified, removes all handlers.

.EXAMPLE
    Unregister-AppLockerEvent -EventName 'RuleCreated' -HandlerId 'handler-123'

.EXAMPLE
    Unregister-AppLockerEvent -EventName 'RuleCreated'
    # Removes all handlers for RuleCreated

.OUTPUTS
    [int] Number of handlers removed
#>
function Unregister-AppLockerEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EventName,

        [Parameter()]
        [string]$HandlerId
    )

    Initialize-EventStorage
    
    if (-not $global:GA_AppLocker_EventHandlers.ContainsKey($EventName)) {
        return 0
    }

    if ($HandlerId) {
        $handlers = $global:GA_AppLocker_EventHandlers[$EventName]
        $toRemove = $handlers | Where-Object { $_.Id -eq $HandlerId }
        if ($toRemove) {
            [void]$handlers.Remove($toRemove)
            return 1
        }
        return 0
    }
    else {
        $count = $global:GA_AppLocker_EventHandlers[$EventName].Count
        $global:GA_AppLocker_EventHandlers.Remove($EventName)
        return $count
    }
}

<#
.SYNOPSIS
    Gets registered event handlers.

.DESCRIPTION
    Returns information about registered handlers for debugging and monitoring.

.PARAMETER EventName
    Optional event name to filter. Returns all handlers if not specified.

.EXAMPLE
    Get-AppLockerEventHandlers

.EXAMPLE
    Get-AppLockerEventHandlers -EventName 'RuleCreated'

.OUTPUTS
    [PSCustomObject[]] Handler information
#>
function Get-AppLockerEventHandlers {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$EventName
    )

    Initialize-EventStorage
    
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    $events = if ($EventName) { @($EventName) } else { $global:GA_AppLocker_EventHandlers.Keys }

    foreach ($evt in $events) {
        $handlers = $global:GA_AppLocker_EventHandlers[$evt]
        if ($handlers) {
            foreach ($h in $handlers) {
                $results.Add([PSCustomObject]@{
                    EventName = $evt
                    HandlerId = $h.Id
                    Priority = $h.Priority
                    RegisteredAt = $h.RegisteredAt
                })
            }
        }
    }

    # Return as array to ensure .Count works correctly - use Write-Output -NoEnumerate
    # to prevent PowerShell from unwrapping single-element arrays
    Write-Output -NoEnumerate $results.ToArray()
}

<#
.SYNOPSIS
    Gets event history.

.DESCRIPTION
    Returns recent event publications for debugging.

.PARAMETER Last
    Number of recent events to return. Default is 20.

.PARAMETER EventName
    Optional filter by event name.

.EXAMPLE
    Get-AppLockerEventHistory -Last 10

.EXAMPLE
    Get-AppLockerEventHistory -EventName 'RuleCreated'

.OUTPUTS
    [PSCustomObject[]] Event history records
#>
function Get-AppLockerEventHistory {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Last = 20,

        [Parameter()]
        [string]$EventName
    )

    Initialize-EventStorage
    
    $events = $global:GA_AppLocker_EventHistory
    
    if ($EventName) {
        $events = $events | Where-Object { $_.EventName -eq $EventName }
    }

    # Return as array to ensure .Count works correctly
    $result = @($events | Select-Object -Last $Last)
    Write-Output -NoEnumerate $result
}

<#
.SYNOPSIS
    Clears event history.

.DESCRIPTION
    Removes all entries from the event history buffer.

.EXAMPLE
    Clear-AppLockerEventHistory

.OUTPUTS
    [int] Number of entries cleared
#>
function Clear-AppLockerEventHistory {
    [CmdletBinding()]
    param()

    Initialize-EventStorage
    
    $count = $global:GA_AppLocker_EventHistory.Count
    $global:GA_AppLocker_EventHistory.Clear()
    return $count
}

<#
.SYNOPSIS
    Gets list of standard event names.

.DESCRIPTION
    Returns the list of standard events used by GA-AppLocker.

.EXAMPLE
    Get-AppLockerStandardEvents

.OUTPUTS
    [string[]] Standard event names
#>
function Get-AppLockerStandardEvents {
    [CmdletBinding()]
    param()

    return $script:StandardEvents
}

#endregion
