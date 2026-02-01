function Update-DeploymentJob {
    [CmdletBinding(DefaultParameterSetName='UpdateFields')]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$JobId,

        [Parameter(Mandatory=$false)]
        [string]$GPOName,

        [Parameter(Mandatory=$false)]
        [string]$Schedule,

        [Parameter(Mandatory=$false)]
        [string[]]$TargetOUs
    )

    # Standard module pattern start
    try {
        Write-AppLockerLog -Message "Starting Update-DeploymentJob for JobId: $JobId" -Level INFO

        # 2. Loads the job JSON from $AppLockerDataPath\Deployments\$JobId.json.
        $jobFilePath = Join-Path -Path $global:GA_AppLockerDataPath -ChildPath "Deployments\$JobId.json"
        
        if (-not (Test-Path -Path $jobFilePath -PathType Leaf)) {
            # Rule 3: Validate that the job exists
            throw "Deployment job file not found at: $jobFilePath"
        }

        # Read file contents (assuming PS 5.1 compatibility for simple file read)
        $jobContent = Get-Content -Path $jobFilePath -Raw -Encoding UTF8
        $job = $jobContent | ConvertFrom-Json

        # 3. Validates that the job exists and its Status is 'Pending'.
        if ($null -eq $job -or $null -eq $job.Status) {
            throw "Loaded content is not a valid job object or missing 'Status' property."
        }

        if ($job.Status -ne 'Pending') {
            throw "Job Status must be 'Pending' for updates. Current Status: $($job.Status)"
        }

        $updated = $false
        
        # 4. Updates the provided fields.
        if ($PSBoundParameters.ContainsKey('GPOName')) {
            $job.GPOName = $GPOName
            $updated = $true
        }
        if ($PSBoundParameters.ContainsKey('Schedule')) {
            $job.Schedule = $Schedule
            $updated = $true
        }
        if ($PSBoundParameters.ContainsKey('TargetOUs')) {
            $job.TargetOUs = $TargetOUs
            $updated = $true
        }

        if (-not $updated) {
            Write-AppLockerLog -Message "No updatable fields provided for JobId: $JobId. Skipping save." -Level WARN
        } else {
            Write-AppLockerLog -Message "Job $($JobId) updated fields: GPOName='$GPOName', Schedule='$Schedule', TargetOUs='$($TargetOUs -join ';')'" -Level INFO
        }

        # 5. Saves the updated JSON back to disk.
        $job | ConvertTo-Json -Depth 10 | Set-Content -Path $jobFilePath -Encoding UTF8
        Write-AppLockerLog -Message "Successfully saved updated job to $jobFilePath" -Level INFO

        # 6. Returns a standard result object
        return @{ Success = $true; Data = $job; Error = $null }

    }
    catch {
        Write-AppLockerLog -Message "Failed to update deployment job $($JobId): $($_.Exception.Message)" -Level ERROR
        # 6. Returns a standard result object on failure
        return @{ Success = $false; Data = $null; Error = $_.Exception.Message }
    }
}