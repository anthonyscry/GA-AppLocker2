#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Cache Manager functions.

.DESCRIPTION
    Tests the caching system including TTL, factory functions, invalidation.

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Unit\Cache.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\GA-AppLocker\GA-AppLocker.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}

Describe 'Cache Manager' -Tag 'Unit', 'Cache' {

    BeforeEach {
        # Clear cache before each test
        Clear-AppLockerCache | Out-Null
    }

    Context 'Set-CachedValue and Get-CachedValue' {

        It 'Stores and retrieves a simple value' {
            Set-CachedValue -Key 'TestKey' -Value 'TestValue'
            
            $result = Get-CachedValue -Key 'TestKey'
            
            $result | Should -Be 'TestValue'
        }

        It 'Stores and retrieves complex objects' {
            $obj = @{
                Name = 'Test'
                Count = 42
                Items = @('a', 'b', 'c')
            }
            Set-CachedValue -Key 'ComplexKey' -Value $obj

            $result = Get-CachedValue -Key 'ComplexKey'

            $result.Name | Should -Be 'Test'
            $result.Count | Should -Be 42
            $result.Items | Should -Contain 'b'
        }

        It 'Returns null for non-existent keys' {
            $result = Get-CachedValue -Key 'NonExistentKey'
            
            $result | Should -BeNullOrEmpty
        }

        It 'Stores null values correctly' {
            Set-CachedValue -Key 'NullKey' -Value $null

            # Should return null, not cache miss
            $exists = Test-CacheKey -Key 'NullKey'
            $exists | Should -BeTrue
        }
    }

    Context 'TTL Expiration' {

        It 'Returns cached value within TTL' {
            Set-CachedValue -Key 'TTLKey' -Value 'Valid' -TTLSeconds 60

            $result = Get-CachedValue -Key 'TTLKey' -MaxAgeSeconds 60

            $result | Should -Be 'Valid'
        }

        It 'Returns null for expired values' {
            Set-CachedValue -Key 'ExpiredKey' -Value 'Old' -TTLSeconds 1
            
            # Wait for expiration
            Start-Sleep -Milliseconds 1100

            $result = Get-CachedValue -Key 'ExpiredKey' -MaxAgeSeconds 1

            $result | Should -BeNullOrEmpty
        }

        It 'Respects MaxAgeSeconds parameter' {
            Set-CachedValue -Key 'AgeKey' -Value 'Data' -TTLSeconds 300

            # Value exists but we request shorter max age
            Start-Sleep -Milliseconds 100
            
            # Should still return value with default max age
            $result1 = Get-CachedValue -Key 'AgeKey' -MaxAgeSeconds 300
            $result1 | Should -Be 'Data'
        }
    }

    Context 'Factory Functions' {

        It 'Executes factory on cache miss' {
            $script:FactoryCallCount = 0
            $factory = {
                $script:FactoryCallCount++
                return 'FactoryValue'
            }

            $result = Get-CachedValue -Key 'FactoryKey' -Factory $factory

            $result | Should -Be 'FactoryValue'
            $script:FactoryCallCount | Should -Be 1
        }

        It 'Does not execute factory on cache hit' {
            Set-CachedValue -Key 'PresetKey' -Value 'Preset'
            $script:FactoryCallCount = 0
            $factory = {
                $script:FactoryCallCount++
                return 'ShouldNotSee'
            }

            $result = Get-CachedValue -Key 'PresetKey' -Factory $factory

            $result | Should -Be 'Preset'
            $script:FactoryCallCount | Should -Be 0
        }

        It 'Caches factory result for subsequent calls' {
            $script:FactoryCallCount = 0
            $factory = {
                $script:FactoryCallCount++
                return "Call$($script:FactoryCallCount)"
            }

            $result1 = Get-CachedValue -Key 'CacheFactoryKey' -Factory $factory
            $result2 = Get-CachedValue -Key 'CacheFactoryKey' -Factory $factory

            $result1 | Should -Be 'Call1'
            $result2 | Should -Be 'Call1'  # Same cached value
            $script:FactoryCallCount | Should -Be 1
        }

        It 'ForceRefresh bypasses cache and executes factory' {
            Set-CachedValue -Key 'ForceKey' -Value 'Old'
            $factory = { return 'New' }

            $result = Get-CachedValue -Key 'ForceKey' -Factory $factory -ForceRefresh

            $result | Should -Be 'New'
        }
    }

    Context 'Clear-AppLockerCache' {

        It 'Clears specific key' {
            Set-CachedValue -Key 'Key1' -Value 'V1'
            Set-CachedValue -Key 'Key2' -Value 'V2'

            Clear-AppLockerCache -Key 'Key1'

            Get-CachedValue -Key 'Key1' | Should -BeNullOrEmpty
            Get-CachedValue -Key 'Key2' | Should -Be 'V2'
        }

        It 'Clears by pattern' {
            Set-CachedValue -Key 'Rule_1' -Value 'R1'
            Set-CachedValue -Key 'Rule_2' -Value 'R2'
            Set-CachedValue -Key 'Policy_1' -Value 'P1'

            $removed = Clear-AppLockerCache -Pattern 'Rule_*'

            $removed | Should -Be 2
            Get-CachedValue -Key 'Rule_1' | Should -BeNullOrEmpty
            Get-CachedValue -Key 'Rule_2' | Should -BeNullOrEmpty
            Get-CachedValue -Key 'Policy_1' | Should -Be 'P1'
        }

        It 'Clears all when no parameters' {
            Set-CachedValue -Key 'A' -Value 1
            Set-CachedValue -Key 'B' -Value 2
            Set-CachedValue -Key 'C' -Value 3

            $removed = Clear-AppLockerCache

            $removed | Should -Be 3
            Get-CachedValue -Key 'A' | Should -BeNullOrEmpty
        }
    }

    Context 'Test-CacheKey' {

        It 'Returns true for existing valid key' {
            Set-CachedValue -Key 'ExistsKey' -Value 'Data' -TTLSeconds 60

            $result = Test-CacheKey -Key 'ExistsKey' -MaxAgeSeconds 60

            $result | Should -BeTrue
        }

        It 'Returns false for non-existent key' {
            $result = Test-CacheKey -Key 'MissingKey'

            $result | Should -BeFalse
        }

        It 'Returns false for expired key' {
            Set-CachedValue -Key 'ExpiredTestKey' -Value 'Data' -TTLSeconds 1
            Start-Sleep -Milliseconds 1100

            $result = Test-CacheKey -Key 'ExpiredTestKey' -MaxAgeSeconds 1

            $result | Should -BeFalse
        }
    }

    Context 'Get-CacheStatistics' {

        It 'Tracks hits and misses' {
            Clear-AppLockerCache
            # Reset stats
            Get-CacheStatistics -Reset | Out-Null

            Set-CachedValue -Key 'StatsKey' -Value 'Data'
            Get-CachedValue -Key 'StatsKey' | Out-Null  # Hit
            Get-CachedValue -Key 'StatsKey' | Out-Null  # Hit
            Get-CachedValue -Key 'Missing' | Out-Null   # Miss

            $stats = Get-CacheStatistics

            $stats.Hits | Should -Be 2
            $stats.Misses | Should -Be 1
        }

        It 'Calculates hit rate correctly' {
            Get-CacheStatistics -Reset | Out-Null
            Set-CachedValue -Key 'HitRateKey' -Value 'Data'
            
            1..3 | ForEach-Object { Get-CachedValue -Key 'HitRateKey' | Out-Null }  # 3 hits
            Get-CachedValue -Key 'Miss1' | Out-Null  # 1 miss

            $stats = Get-CacheStatistics

            $stats.HitRate | Should -Be '75%'
        }

        It 'Reset clears statistics' {
            Set-CachedValue -Key 'ResetKey' -Value 'Data'
            Get-CachedValue -Key 'ResetKey' | Out-Null

            $before = Get-CacheStatistics -Reset
            $after = Get-CacheStatistics

            $before.Hits | Should -BeGreaterThan 0
            $after.Hits | Should -Be 0
        }
    }

    Context 'Invoke-CacheCleanup' {

        It 'Removes expired entries' {
            Set-CachedValue -Key 'Fresh' -Value 'Data' -TTLSeconds 300
            Set-CachedValue -Key 'Stale' -Value 'OldData' -TTLSeconds 1
            
            Start-Sleep -Milliseconds 1100

            $removed = Invoke-CacheCleanup

            $removed | Should -Be 1
            Get-CachedValue -Key 'Fresh' | Should -Be 'Data'
            Get-CachedValue -Key 'Stale' | Should -BeNullOrEmpty
        }
    }
}
