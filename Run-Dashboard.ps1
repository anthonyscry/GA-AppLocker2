# GA-AppLocker Dashboard Launcher
# Copy and paste this entire block into PowerShell to run the dashboard
# Log file: %LOCALAPPDATA%\GA-AppLocker\Logs\GA-AppLocker_YYYY-MM-DD.log
# Troubleshooting scripts: .\Troubleshooting\

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Remove any previously loaded version so we always get the latest
if (Get-Module GA-AppLocker -ErrorAction SilentlyContinue) {
    Remove-Module GA-AppLocker -Force -ErrorAction SilentlyContinue
}
# Also remove sub-modules that may be cached from a prior version
Get-Module GA-AppLocker.* -ErrorAction SilentlyContinue | Remove-Module -Force -ErrorAction SilentlyContinue

Import-Module "$PSScriptRoot\GA-AppLocker\GA-AppLocker.psd1" -Force
Start-AppLockerDashboard -SkipPrerequisites
