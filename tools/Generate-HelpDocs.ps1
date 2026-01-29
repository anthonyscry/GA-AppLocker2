<#
.SYNOPSIS
    Generates platyPS markdown help documentation for all GA-AppLocker exported commands.
.DESCRIPTION
    Imports the GA-AppLocker module and uses platyPS to generate markdown help files
    in docs/cmdlets/. Creates one .md file per exported command.
#>
[CmdletBinding()]
param(
    [string]$OutputPath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Resolve base directory
$baseDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
if (-not $OutputPath) {
    $OutputPath = Join-Path (Join-Path $baseDir 'docs') 'cmdlets'
}

# Ensure output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "[+] Created output directory: $OutputPath" -ForegroundColor Green
}

# Import platyPS
try {
    Import-Module platyPS -Force -ErrorAction Stop
    Write-Host "[+] platyPS loaded" -ForegroundColor Green
} catch {
    Write-Error "platyPS not installed. Run: Install-Module -Name platyPS -Force -Scope CurrentUser"
    return
}

# Import GA-AppLocker
$modulePath = Join-Path (Join-Path $baseDir 'GA-AppLocker') 'GA-AppLocker.psd1'
try {
    Import-Module $modulePath -Force -ErrorAction Stop
    $mod = Get-Module -Name 'GA-AppLocker'
    $cmdCount = ($mod.ExportedCommands).Count
    Write-Host "[+] GA-AppLocker loaded ($cmdCount exported commands)" -ForegroundColor Green
} catch {
    Write-Error "Failed to import GA-AppLocker: $_"
    return
}

# Generate markdown help
Write-Host "[*] Generating markdown help docs..." -ForegroundColor Cyan
try {
    $params = @{
        Module                = 'GA-AppLocker'
        OutputFolder          = $OutputPath
        AlphabeticParamsOrder = $true
        WithModulePage        = $true
        ExcludeDontShow       = $true
        Force                 = $true
    }
    $files = New-MarkdownHelp @params
    Write-Host "[+] Generated $($files.Count) markdown files in $OutputPath" -ForegroundColor Green
} catch {
    Write-Warning "New-MarkdownHelp had errors: $_"
    Write-Host "[*] Attempting per-command generation as fallback..." -ForegroundColor Yellow
    
    $commands = (Get-Module 'GA-AppLocker').ExportedCommands.Keys | Sort-Object
    $generated = 0
    $failed = @()
    
    foreach ($cmd in $commands) {
        try {
            New-MarkdownHelp -Command $cmd -OutputFolder $OutputPath -Force -ErrorAction Stop | Out-Null
            $generated++
        } catch {
            $failed += $cmd
        }
    }
    
    Write-Host "[+] Generated $generated/$($commands.Count) command docs" -ForegroundColor Green
    if ($failed.Count -gt 0) {
        Write-Warning "Failed to generate docs for $($failed.Count) commands:"
        $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
}

# Summary
$mdFiles = Get-ChildItem -Path $OutputPath -Filter '*.md' -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Output:   $OutputPath"
Write-Host "Files:    $($mdFiles.Count) markdown docs"
Write-Host ""
Write-Host "To update existing docs after code changes:" -ForegroundColor Gray
Write-Host "  Update-MarkdownHelp -Path '$OutputPath'" -ForegroundColor Gray
Write-Host ""
Write-Host "To generate MAML XML for Get-Help:" -ForegroundColor Gray
Write-Host "  New-ExternalHelp -Path '$OutputPath' -OutputPath 'GA-AppLocker\en-US'" -ForegroundColor Gray
