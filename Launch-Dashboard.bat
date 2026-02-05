@echo off
REM GA-AppLocker Dashboard Launcher
REM Run as Administrator for full functionality

cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File ".\Run-Dashboard.ps1"
