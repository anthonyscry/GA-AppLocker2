        New-AppLockerGPO -GPOName "AppLocker-Workstations"
        # Check if user has GPO write permissions first\        $permCheck = Test-GPOWritePermission\        if (-not $permCheck.Success) {\            return @{\                Success = $false\                Error   = $permCheck.Error\            }\        }\
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GPOName,

        [Parameter(Mandatory = $false)]
        [string]$Comment = 'Created by GA-AppLocker Dashboard'
    )

    try {
        # Check if user has GPO write permissions first
