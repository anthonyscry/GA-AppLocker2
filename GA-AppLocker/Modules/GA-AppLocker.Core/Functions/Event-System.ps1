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
# Event handlers registry
if (-not $script:EventHandlers) {
    $script:EventHandlers = [hashtable]::Synchronized(@{})
}

# Event history for debugging (circular buffer)
if (-not $script:EventHistory) {
    $script:EventHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
}
$script:EventHistoryMaxSize = 100

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

    if (-not $script:EventHandlers.ContainsKey($EventName)) {
        $script:EventHandlers[$EventName] = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    $handlerEntry = [PSCustomObject]@{
        Id = $HandlerId
        Handler = $Handler
        Priority = $Priority
        RegisteredAt = [DateTime]::UtcNow
    }

    $script:EventHandlers[$EventName].Add($handlerEntry)
    
    # Sort by priority
    $sorted = $script:EventHandlers[$EventName] | Sort-Object Priority
    $script:EventHandlers[$EventName] = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($h in $sorted) {
        $script:EventHandlers[$EventName].Add($h)
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

    $eventRecord = [PSCustomObject]@{
        EventName = $EventName
        Timestamp = [DateTime]::UtcNow
        Data = $EventData
        HandlerCount = 0
        Errors = @()
    }

    # Add to history (circular buffer)
    $script:EventHistory.Add($eventRecord)
    if ($script:EventHistory.Count -gt $script:EventHistoryMaxSize) {
        $script:EventHistory.RemoveAt(0)
    }

    $handlers = $script:EventHandlers[$EventName]
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

    if (-not $script:EventHandlers.ContainsKey($EventName)) {
        return 0
    }

    if ($HandlerId) {
        $handlers = $script:EventHandlers[$EventName]
        $toRemove = $handlers | Where-Object { $_.Id -eq $HandlerId }
        if ($toRemove) {
            $handlers.Remove($toRemove)
            return 1
        }
        return 0
    }
    else {
        $count = $script:EventHandlers[$EventName].Count
        $script:EventHandlers.Remove($EventName)
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

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    $events = if ($EventName) { @($EventName) } else { $script:EventHandlers.Keys }

    foreach ($evt in $events) {
        $handlers = $script:EventHandlers[$evt]
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

    return $results
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

    $events = $script:EventHistory
    
    if ($EventName) {
        $events = $events | Where-Object { $_.EventName -eq $EventName }
    }

    return $events | Select-Object -Last $Last
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

    $count = $script:EventHistory.Count
    $script:EventHistory.Clear()
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
