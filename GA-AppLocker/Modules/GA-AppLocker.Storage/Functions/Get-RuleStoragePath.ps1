function Get-RuleStoragePath {
    <#
    .SYNOPSIS
        Gets the path to the rules storage directory.

    .DESCRIPTION
        Gets the path to the rules storage directory.

    .OUTPUTS
        [string] The full path to the rules storage directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $dataPath = try { Get-AppLockerDataPath } catch { Join-Path $env:LOCALAPPDATA 'GA-AppLocker' }
    return Join-Path $dataPath 'Rules'
}
