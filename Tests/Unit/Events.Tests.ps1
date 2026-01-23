#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Event System functions.

.DESCRIPTION
    Tests the publish/subscribe event system.

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Unit\Events.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}

Describe 'Event System' -Tag 'Unit', 'Events' {

    BeforeEach {
        # Clear all handlers and history before each test
        foreach ($event in (Get-AppLockerStandardEvents)) {
            Unregister-AppLockerEvent -EventName $event | Out-Null
        }
        Unregister-AppLockerEvent -EventName 'TestEvent' -ErrorAction SilentlyContinue | Out-Null
        Clear-AppLockerEventHistory | Out-Null
    }

    Context 'Register-AppLockerEvent' {

        It 'Registers a handler and returns handler ID' {
            $handlerId = Register-AppLockerEvent -EventName 'TestEvent' -Handler { }

            $handlerId | Should -Not -BeNullOrEmpty
            $handlerId | Should -Match '^[a-f0-9\-]{36}$'
        }

        It 'Allows custom handler ID' {
            $customId = 'my-custom-handler'
            $handlerId = Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId $customId

            $handlerId | Should -Be $customId
        }

        It 'Registers multiple handlers for same event' {
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'h1'
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'h2'

            $handlers = Get-AppLockerEventHandlers -EventName 'TestEvent'

            $handlers.Count | Should -Be 2
        }

        It 'Respects priority ordering' {
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'low' -Priority 200
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'high' -Priority 10
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'mid' -Priority 100

            $handlers = Get-AppLockerEventHandlers -EventName 'TestEvent'

            $handlers[0].HandlerId | Should -Be 'high'
            $handlers[1].HandlerId | Should -Be 'mid'
            $handlers[2].HandlerId | Should -Be 'low'
        }
    }

    Context 'Publish-AppLockerEvent' {

        It 'Executes registered handlers' {
            $script:HandlerExecuted = $false
            Register-AppLockerEvent -EventName 'TestEvent' -Handler {
                $script:HandlerExecuted = $true
            }

            Publish-AppLockerEvent -EventName 'TestEvent'

            $script:HandlerExecuted | Should -BeTrue
        }

        It 'Passes event data to handlers' {
            $script:ReceivedData = $null
            Register-AppLockerEvent -EventName 'TestEvent' -Handler {
                param($EventData)
                $script:ReceivedData = $EventData
            }

            Publish-AppLockerEvent -EventName 'TestEvent' -EventData @{ Key = 'Value'; Count = 42 }

            $script:ReceivedData.Key | Should -Be 'Value'
            $script:ReceivedData.Count | Should -Be 42
        }

        It 'Executes handlers in priority order' {
            $script:ExecutionOrder = [System.Collections.Generic.List[string]]::new()
            
            Register-AppLockerEvent -EventName 'TestEvent' -Handler {
                $script:ExecutionOrder.Add('third')
            } -Priority 300

            Register-AppLockerEvent -EventName 'TestEvent' -Handler {
                $script:ExecutionOrder.Add('first')
            } -Priority 100

            Register-AppLockerEvent -EventName 'TestEvent' -Handler {
                $script:ExecutionOrder.Add('second')
            } -Priority 200

            Publish-AppLockerEvent -EventName 'TestEvent'

            $script:ExecutionOrder[0] | Should -Be 'first'
            $script:ExecutionOrder[1] | Should -Be 'second'
            $script:ExecutionOrder[2] | Should -Be 'third'
        }

        It 'Returns success when no handlers registered' {
            $result = Publish-AppLockerEvent -EventName 'NoHandlersEvent'

            $result.Success | Should -BeTrue
            $result.HandlersExecuted | Should -Be 0
        }

        It 'Continues executing handlers after one fails' {
            $script:Handler1Ran = $false
            $script:Handler2Ran = $false

            Register-AppLockerEvent -EventName 'TestEvent' -Handler {
                $script:Handler1Ran = $true
                throw "Intentional failure"
            } -Priority 10

            Register-AppLockerEvent -EventName 'TestEvent' -Handler {
                $script:Handler2Ran = $true
            } -Priority 20

            $result = Publish-AppLockerEvent -EventName 'TestEvent'

            $script:Handler1Ran | Should -BeTrue
            $script:Handler2Ran | Should -BeTrue
            $result.Errors.Count | Should -Be 1
        }

        It 'Records errors from failed handlers' {
            Register-AppLockerEvent -EventName 'TestEvent' -Handler {
                throw "Test error message"
            } -HandlerId 'failing-handler'

            $result = Publish-AppLockerEvent -EventName 'TestEvent'

            $result.Success | Should -BeFalse
            $result.Errors[0] | Should -Match 'failing-handler'
            $result.Errors[0] | Should -Match 'Test error message'
        }
    }

    Context 'Unregister-AppLockerEvent' {

        It 'Removes specific handler by ID' {
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'keep'
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'remove'

            $removed = Unregister-AppLockerEvent -EventName 'TestEvent' -HandlerId 'remove'

            $removed | Should -Be 1
            $handlers = Get-AppLockerEventHandlers -EventName 'TestEvent'
            $handlers.Count | Should -Be 1
            $handlers[0].HandlerId | Should -Be 'keep'
        }

        It 'Removes all handlers when no ID specified' {
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'h1'
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'h2'

            $removed = Unregister-AppLockerEvent -EventName 'TestEvent'

            $removed | Should -Be 2
            $handlers = Get-AppLockerEventHandlers -EventName 'TestEvent'
            $handlers.Count | Should -Be 0
        }

        It 'Returns 0 when handler not found' {
            $removed = Unregister-AppLockerEvent -EventName 'TestEvent' -HandlerId 'nonexistent'

            $removed | Should -Be 0
        }
    }

    Context 'Get-AppLockerEventHandlers' {

        It 'Returns handlers for specific event' {
            Register-AppLockerEvent -EventName 'Event1' -Handler { } -HandlerId 'e1h1'
            Register-AppLockerEvent -EventName 'Event2' -Handler { } -HandlerId 'e2h1'

            $handlers = Get-AppLockerEventHandlers -EventName 'Event1'

            $handlers.Count | Should -Be 1
            $handlers[0].HandlerId | Should -Be 'e1h1'

            Unregister-AppLockerEvent -EventName 'Event1' | Out-Null
            Unregister-AppLockerEvent -EventName 'Event2' | Out-Null
        }

        It 'Returns all handlers when no event specified' {
            Register-AppLockerEvent -EventName 'Event1' -Handler { } -HandlerId 'e1'
            Register-AppLockerEvent -EventName 'Event2' -Handler { } -HandlerId 'e2'

            $handlers = Get-AppLockerEventHandlers

            $handlers.Count | Should -BeGreaterOrEqual 2

            Unregister-AppLockerEvent -EventName 'Event1' | Out-Null
            Unregister-AppLockerEvent -EventName 'Event2' | Out-Null
        }

        It 'Includes registration timestamp' {
            $before = [DateTime]::UtcNow
            Register-AppLockerEvent -EventName 'TestEvent' -Handler { } -HandlerId 'timestamped'
            $after = [DateTime]::UtcNow

            $handlers = Get-AppLockerEventHandlers -EventName 'TestEvent'

            $handlers[0].RegisteredAt | Should -BeGreaterOrEqual $before
            $handlers[0].RegisteredAt | Should -BeLessOrEqual $after
        }
    }

    Context 'Event History' {

        It 'Records published events' {
            Publish-AppLockerEvent -EventName 'TestEvent' -EventData @{ Test = 1 }

            $history = Get-AppLockerEventHistory -Last 1

            $history.Count | Should -Be 1
            $history[0].EventName | Should -Be 'TestEvent'
            $history[0].Data.Test | Should -Be 1
        }

        It 'Filters by event name' {
            Publish-AppLockerEvent -EventName 'Event1' -EventData @{ Type = 1 }
            Publish-AppLockerEvent -EventName 'Event2' -EventData @{ Type = 2 }
            Publish-AppLockerEvent -EventName 'Event1' -EventData @{ Type = 3 }

            $history = Get-AppLockerEventHistory -EventName 'Event1'

            $history.Count | Should -Be 2
            $history | ForEach-Object { $_.EventName | Should -Be 'Event1' }
        }

        It 'Limits results with Last parameter' {
            1..10 | ForEach-Object { Publish-AppLockerEvent -EventName 'TestEvent' -EventData @{ Num = $_ } }

            $history = Get-AppLockerEventHistory -Last 3

            $history.Count | Should -Be 3
        }

        It 'Clear-AppLockerEventHistory removes all history' {
            Publish-AppLockerEvent -EventName 'TestEvent'
            Publish-AppLockerEvent -EventName 'TestEvent'

            $cleared = Clear-AppLockerEventHistory

            $cleared | Should -BeGreaterOrEqual 2
            $history = Get-AppLockerEventHistory
            $history.Count | Should -Be 0
        }
    }

    Context 'Standard Events' {

        It 'Returns list of standard event names' {
            $events = Get-AppLockerStandardEvents

            $events | Should -Contain 'RuleCreated'
            $events | Should -Contain 'RuleUpdated'
            $events | Should -Contain 'PolicyCreated'
            $events | Should -Contain 'ScanCompleted'
            $events | Should -Contain 'IndexRebuilt'
        }
    }
}
