<#
.SYNOPSIS
    Measures and logs the duration of an operation.

.DESCRIPTION
    Wrapper function that measures execution time and logs the duration.
    Automatically logs success/failure with timing information.

.PARAMETER Operation
    Name of the operation being measured.

.PARAMETER ScriptBlock
    Script block containing the operation to execute.

.PARAMETER Panel
    Optional panel name for panel-specific performance tracking.

.EXAMPLE
    Measure-AppLockerOperation -Operation "Load Rules" -ScriptBlock { Get-AllRules } -Panel "Rules"
    # Logs: "[2026-02-04 13:00:00] [INFO] [Rules] Load Rules completed (125ms)"

.EXAMPLE
    Measure-AppLockerOperation -Operation "Scan DC01" -ScriptBlock { Get-RemoteArtifacts -ComputerName DC01 }
    # Logs: "[2026-02-04 13:00:05] [INFO] Scan DC01 completed (3250ms)"

.OUTPUTS
    Returns the result of the script block on success.
    Throws on failure after logging error.

.NOTES
    Author: GA-AppLocker Team
    Version: 1.0.0
    Requires: PowerShell 5.1+
#>
function Measure-AppLockerOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [string]$Panel
    )

    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        $result = & $ScriptBlock
        $sw.Stop()

        if ($sw.Elapsed.TotalMilliseconds -gt 1000) {
            # Slow operations (>1s) logged as Info
            Write-AppLockerLog -Message "$Operation completed" -Level Info -Duration $sw.Elapsed -Panel $Panel
        }

        return $result
    }
    catch {
        $sw.Stop()
        $durationMs = $sw.Elapsed.TotalMilliseconds

        # Log error with duration
        Write-AppLockerLog -Message "$Operation failed after ${durationMs}ms: $($_.Exception.Message)" -Level Error -Duration $sw.Elapsed -Panel $Panel

        # Re-throw to preserve call stack
        throw
    }
}
