# GA-AppLocker Dashboard Launcher
# Copy and paste this entire block into PowerShell to run the dashboard

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Import-Module "$PSScriptRoot\GA-AppLocker\GA-AppLocker.psd1" -Force
Start-AppLockerDashboard -SkipPrerequisites
