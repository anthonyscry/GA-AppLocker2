param(
    [Parameter(Mandatory)]
    [string]$Path
)

if (-not (Test-Path -Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$content = Get-Content -Path $Path -Raw
$pattern = '\$job\s*\|\s*ConvertTo-Json\s*-Depth\s*5\s*\|\s*Set-Content\s*-Path\s*\$jobFile\s*-Encoding\s*UTF8'
$replacement = 'Write-DeploymentJobFile -Path $jobFile -Job $job'

$updated = [regex]::Replace($content, $pattern, $replacement)

if ($updated -ne $content) {
    Set-Content -Path $Path -Value $updated -Encoding UTF8
    Write-Output "Updated: $Path"
} else {
    Write-Output "No changes: $Path"
}
