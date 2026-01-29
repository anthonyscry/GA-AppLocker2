# Prepare Release Artifact
$ErrorActionPreference = 'Stop'
$version = 'v1.1.0'
$releaseDir = Join-Path $PSScriptRoot "Release_$version"
$zipPath = Join-Path $PSScriptRoot "GA-AppLocker-$version.zip"

# 1. Clean previous attempts
if (Test-Path $releaseDir) { Remove-Item $releaseDir -Recurse -Force }
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# 2. Create Directory Structure
New-Item -Path $releaseDir -ItemType Directory | Out-Null
Write-Host "Created staging dir: $releaseDir"

# 3. Copy Critical Artifacts
$artifacts = @(
    "GA-AppLocker",       # The main module folder
    "docs",               # Documentation
    "Run-Dashboard.ps1",  # Launcher
    "README.md",          # Readme
    "CHANGELOG.md"        # Changelog
)

foreach ($item in $artifacts) {
    $src = Join-Path $PSScriptRoot $item
    $dst = Join-Path $releaseDir $item
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dst -Recurse -Force
        Write-Host "  Copied: $item"
    } else {
        Write-Warning "  Missing: $item"
    }
}

# 4. Remove development cruft from the staging copy
# (e.g., if we copied the whole folder, we'd remove .git, but we selected specific items)
# Just cleaning up potential development artifacts inside docs if any (like archive)
# User asked for "necessary files and documentation". 'docs/archive' is old takeover stuff, maybe exclude?
# I'll exclude docs/archive to keep it clean.
$archiveDir = Join-Path $releaseDir "docs\archive"
if (Test-Path $archiveDir) {
    Remove-Item $archiveDir -Recurse -Force
    Write-Host "  Cleaned up: docs/archive (not needed for release)"
}

# 5. Create Zip
Write-Host "Zipping to $zipPath..."
Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipPath
Write-Host "Success! Artifact ready."
