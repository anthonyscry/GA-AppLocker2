# Package GA-AppLocker Release
# Creates a minimal zip containing only what's needed to run the application.
$ErrorActionPreference = 'Stop'

$version = 'v1.2.0'
$projectRoot = Split-Path $PSScriptRoot -Parent
$releaseDir = Join-Path $projectRoot "Release_$version"
$zipPath = Join-Path $projectRoot "GA-AppLocker-$version.zip"

# 1. Clean previous attempts
if (Test-Path $releaseDir) { Remove-Item $releaseDir -Recurse -Force }
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# 2. Create staging directory
New-Item -Path $releaseDir -ItemType Directory | Out-Null
Write-Host "Staging release $version ..." -ForegroundColor Cyan

# 3. Copy runtime artifacts only
$artifacts = @(
    'GA-AppLocker'        # Main module (all sub-modules, GUI, manifests)
    'Run-Dashboard.ps1'   # Launcher
    'README.md'           # User documentation
    'CHANGELOG.md'        # Version history
)

foreach ($item in $artifacts) {
    $src = Join-Path $projectRoot $item
    $dst = Join-Path $releaseDir $item
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dst -Recurse -Force
        Write-Host "  + $item" -ForegroundColor Green
    } else {
        Write-Warning "  MISSING: $item"
    }
}

# 4. Strip dev-only files from the staging copy
$devCruft = @(
    (Join-Path $releaseDir 'GA-AppLocker\.context')
)
foreach ($path in $devCruft) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
        Write-Host "  - Removed dev artifact: $path" -ForegroundColor DarkGray
    }
}

# 5. Create zip
Write-Host "`nCreating $zipPath ..." -ForegroundColor Cyan
Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipPath -Force
$sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
Write-Host "Release packaged: GA-AppLocker-$version.zip ($sizeMB MB)" -ForegroundColor Green

# 6. Cleanup staging directory
Remove-Item $releaseDir -Recurse -Force
Write-Host 'Staging directory cleaned up.' -ForegroundColor DarkGray
