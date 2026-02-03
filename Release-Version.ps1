<#
.SYNOPSIS
    Automated release script for GA-AppLocker
    
.DESCRIPTION
    Creates a GitHub release with ZIP artifact automatically.
    Reads version from GA-AppLocker.psd1 and release notes from CHANGELOG.md.
    
.PARAMETER Version
    Version to release (e.g., "1.2.59"). If not specified, reads from .psd1 file.
    
.PARAMETER SkipZip
    Skip ZIP creation (useful if ZIP already exists)
    
.PARAMETER DryRun
    Show what would be done without actually creating the release
    
.EXAMPLE
    .\Release-Version.ps1
    # Reads version from .psd1, creates release automatically
    
.EXAMPLE
    .\Release-Version.ps1 -Version "1.2.60"
    # Creates release for specific version
    
.EXAMPLE
    .\Release-Version.ps1 -DryRun
    # Preview what would be released
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Version,
    
    [Parameter()]
    [switch]$SkipZip,
    
    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Get script directory
$ScriptRoot = $PSScriptRoot

# Read version from .psd1 if not specified
if (-not $Version) {
    $ManifestPath = Join-Path $ScriptRoot "GA-AppLocker\GA-AppLocker.psd1"
    if (-not (Test-Path $ManifestPath)) {
        Write-Error "Manifest not found: $ManifestPath"
        exit 1
    }
    
    $ManifestContent = Get-Content $ManifestPath -Raw
    if ($ManifestContent -match "ModuleVersion\s*=\s*'([^']+)'") {
        $Version = $Matches[1]
        Write-Host "✓ Detected version from manifest: $Version" -ForegroundColor Green
    } else {
        Write-Error "Could not parse version from manifest"
        exit 1
    }
}

# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "Invalid version format: $Version (expected: X.Y.Z)"
    exit 1
}

$TagName = "v$Version"
$ZipName = "GA-AppLocker-v$Version.zip"
$ZipPath = Join-Path $ScriptRoot $ZipName

Write-Host "`n=== GA-AppLocker Release Automation ===" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor White
Write-Host "Tag: $TagName" -ForegroundColor White
Write-Host "ZIP: $ZipName" -ForegroundColor White

# Check if gh CLI is available
$ghPath = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghPath) {
    Write-Error "GitHub CLI (gh) not found. Install from: https://cli.github.com/"
    exit 1
}

# Check if tag exists locally
$tagExists = git tag -l $TagName
if (-not $tagExists) {
    Write-Error "Git tag '$TagName' does not exist. Create it first with: git tag -a $TagName -m 'Release message'"
    exit 1
}

Write-Host "✓ Git tag exists locally" -ForegroundColor Green

# Check if tag is pushed to remote
$remoteTags = git ls-remote --tags origin
if ($remoteTags -notmatch $TagName) {
    Write-Warning "Tag '$TagName' not pushed to remote. Pushing now..."
    if (-not $DryRun) {
        git push origin $TagName
        Write-Host "✓ Tag pushed to remote" -ForegroundColor Green
    }
}

# Extract release notes from CHANGELOG.md
$ChangelogPath = Join-Path $ScriptRoot "CHANGELOG.md"
if (-not (Test-Path $ChangelogPath)) {
    Write-Error "CHANGELOG.md not found"
    exit 1
}

$ChangelogContent = Get-Content $ChangelogPath -Raw
$VersionPattern = "## \[$Version\].*?(?=\n## \[|\z)"
if ($ChangelogContent -match $VersionPattern) {
    $ReleaseNotes = $Matches[0]
    # Remove the version header line
    $ReleaseNotes = $ReleaseNotes -replace "^## \[$Version\][^\n]*\n", ""
    # Trim whitespace
    $ReleaseNotes = $ReleaseNotes.Trim()
    
    # Add installation instructions
    $ReleaseNotes += @"

---

## Installation
1. Download the ZIP file below
2. Extract to your admin workstation
3. Run ``.\Run-Dashboard.ps1`` from PowerShell as Administrator

## Full Changelog
See [CHANGELOG.md](https://github.com/anthonyscry/GA-AppLocker2/blob/main/CHANGELOG.md) for complete version history.
"@
    
    Write-Host "✓ Extracted release notes from CHANGELOG.md" -ForegroundColor Green
} else {
    Write-Error "Could not find version [$Version] in CHANGELOG.md"
    exit 1
}

# Create ZIP if needed
if (-not $SkipZip) {
    Write-Host "`nCreating release ZIP..." -ForegroundColor Yellow
    
    if (Test-Path $ZipPath) {
        Write-Host "  Removing existing ZIP..." -ForegroundColor Gray
        if (-not $DryRun) {
            Remove-Item $ZipPath -Force
        }
    }
    
    $ItemsToZip = @(
        "GA-AppLocker\*"
        "Run-Dashboard.ps1"
        "Run-Dashboard-ForceFresh.ps1"
        "README.md"
        "CHANGELOG.md"
        "Troubleshooting\*"
    )
    
    if (-not $DryRun) {
        Compress-Archive -Path $ItemsToZip -DestinationPath $ZipPath -Force
        $ZipSize = (Get-Item $ZipPath).Length / 1MB
        Write-Host "✓ ZIP created: $([math]::Round($ZipSize, 2)) MB" -ForegroundColor Green
    } else {
        Write-Host "  [DRY RUN] Would create ZIP with:" -ForegroundColor Gray
        $ItemsToZip | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    }
} else {
    if (-not (Test-Path $ZipPath)) {
        Write-Error "ZIP file not found: $ZipPath (use -SkipZip only if ZIP already exists)"
        exit 1
    }
    Write-Host "✓ Using existing ZIP" -ForegroundColor Green
}

# Create GitHub release
Write-Host "`nCreating GitHub release..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "`n[DRY RUN] Would create release with:" -ForegroundColor Cyan
    Write-Host "  Tag: $TagName" -ForegroundColor Gray
    Write-Host "  Title: $TagName - AD Discovery UI Improvements" -ForegroundColor Gray
    Write-Host "  Notes:" -ForegroundColor Gray
    $ReleaseNotes -split "`n" | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    Write-Host "  Asset: $ZipName" -ForegroundColor Gray
    exit 0
}

# Check if release already exists
$existingRelease = gh release view $TagName 2>$null
if ($existingRelease) {
    Write-Warning "Release '$TagName' already exists on GitHub"
    $response = Read-Host "Delete and recreate? (y/N)"
    if ($response -eq 'y') {
        Write-Host "  Deleting existing release..." -ForegroundColor Gray
        gh release delete $TagName --yes
    } else {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

# Create release
try {
    $ReleaseUrl = gh release create $TagName `
        --title "$TagName - GA-AppLocker Release" `
        --notes $ReleaseNotes `
        $ZipPath
    
    Write-Host "✓ Release created successfully!" -ForegroundColor Green
    Write-Host "`nRelease URL: $ReleaseUrl" -ForegroundColor Cyan
    
    # Open in browser
    Start-Process $ReleaseUrl
    
} catch {
    Write-Error "Failed to create release: $_"
    exit 1
}

Write-Host "`n=== Release Complete ===" -ForegroundColor Green
Write-Host "Version $Version is now live on GitHub!" -ForegroundColor White
